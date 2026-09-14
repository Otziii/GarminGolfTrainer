/*
 * mtpsend - minimal MTP file pusher for sideloading Connect IQ apps.
 *
 * Why this exists: libmtp's own mtp-sendfile resolves the destination by
 * walking a full recursive file listing, and the fenix 8 fails
 * get_all_metadata_fast(). That makes "/GARMIN/Apps" unresolvable and every
 * send aborts with "Parent folder could not be found". We sidestep the path
 * parser and talk to the folder IDs directly via LIBMTP_Get_Files_And_Folders,
 * which the watch answers correctly.
 *
 * Build: make -C tools    (needs `brew install libmtp`)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/stat.h>
#include <libmtp.h>

static int progress(uint64_t sent, uint64_t total, void const *const data) {
    (void)data;
    fprintf(stderr, "\r  %llu / %llu bytes (%d%%)",
            (unsigned long long)sent, (unsigned long long)total,
            total ? (int)(sent * 100 / total) : 0);
    return 0;
}

/* An uncached handle is required: the cached one refuses
 * LIBMTP_Get_Files_And_Folders with "tried to use ... on a cached device". */
static LIBMTP_mtpdevice_t *open_device(void) {
    LIBMTP_raw_device_t *raw = NULL;
    int n = 0;
    if (LIBMTP_Detect_Raw_Devices(&raw, &n) != LIBMTP_ERROR_NONE || n < 1) {
        fprintf(stderr,
                "mtpsend: no MTP device found.\n"
                "  - Is the watch plugged in with a data cable?\n"
                "  - Quit Android File Transfer and Garmin Express; they hold\n"
                "    the USB interface exclusively (libusb error -3).\n");
        free(raw);
        return NULL;
    }
    LIBMTP_mtpdevice_t *dev = LIBMTP_Open_Raw_Device_Uncached(&raw[0]);
    free(raw);
    if (!dev) fprintf(stderr, "mtpsend: could not open MTP device\n");
    return dev;
}

static uint32_t storage_of(LIBMTP_mtpdevice_t *dev) {
    return dev->storage ? dev->storage->id : 0;
}

/* Walk a slash-separated path from the storage root, matching case
 * insensitively. Returns the folder id, or 0 if any component is missing. */
static uint32_t resolve_folder(LIBMTP_mtpdevice_t *dev, const char *path) {
    uint32_t parent = LIBMTP_FILES_AND_FOLDERS_ROOT;
    char *dup = strdup(path);
    for (char *tok = strtok(dup, "/"); tok; tok = strtok(NULL, "/")) {
        LIBMTP_file_t *f = LIBMTP_Get_Files_And_Folders(dev, storage_of(dev), parent);
        uint32_t found = 0;
        while (f) {
            if (!found && f->filetype == LIBMTP_FILETYPE_FOLDER &&
                f->filename && strcasecmp(f->filename, tok) == 0) {
                found = f->item_id;
            }
            LIBMTP_file_t *next = f->next;
            LIBMTP_destroy_file_t(f);
            f = next;
        }
        if (!found) {
            fprintf(stderr, "mtpsend: no folder \"%s\" under id %u\n", tok, parent);
            free(dup);
            return 0;
        }
        parent = found;
    }
    free(dup);
    return parent;
}

/* Accepts a literal numeric folder id or a path like GARMIN/Apps. */
static uint32_t as_folder(LIBMTP_mtpdevice_t *dev, const char *spec) {
    char *end = NULL;
    unsigned long n = strtoul(spec, &end, 10);
    if (end && *end == '\0' && n > 0) return (uint32_t)n;
    return resolve_folder(dev, spec);
}

static int cmd_list(LIBMTP_mtpdevice_t *dev, const char *spec) {
    uint32_t parent = as_folder(dev, spec);
    if (!parent) return 1;
    LIBMTP_file_t *f = LIBMTP_Get_Files_And_Folders(dev, storage_of(dev), parent);
    if (!f) printf("(empty or unreadable)\n");
    while (f) {
        printf("%-12u %-40s %10llu  %s\n", f->item_id, f->filename,
               (unsigned long long)f->filesize,
               f->filetype == LIBMTP_FILETYPE_FOLDER ? "DIR" : "file");
        LIBMTP_file_t *next = f->next;
        LIBMTP_destroy_file_t(f);
        f = next;
    }
    return 0;
}

/* MTP happily stores two objects with the same name in one folder, which
 * leaves stale duplicates behind on every reinstall. Drop the old one first. */
static void remove_existing(LIBMTP_mtpdevice_t *dev, uint32_t parent, const char *name) {
    LIBMTP_file_t *f = LIBMTP_Get_Files_And_Folders(dev, storage_of(dev), parent);
    while (f) {
        if (f->filetype != LIBMTP_FILETYPE_FOLDER && f->filename &&
            strcasecmp(f->filename, name) == 0) {
            printf("Replacing existing %s (object %u)\n", f->filename, f->item_id);
            if (LIBMTP_Delete_Object(dev, f->item_id) != 0) {
                fprintf(stderr, "  warning: could not delete old object\n");
                LIBMTP_Clear_Errorstack(dev);
            }
        }
        LIBMTP_file_t *next = f->next;
        LIBMTP_destroy_file_t(f);
        f = next;
    }
}

static int cmd_send(LIBMTP_mtpdevice_t *dev, const char *local,
                    const char *spec, const char *remote) {
    struct stat st;
    if (stat(local, &st) != 0) { perror(local); return 1; }

    uint32_t parent = as_folder(dev, spec);
    if (!parent) return 1;
    remove_existing(dev, parent, remote);

    LIBMTP_file_t *meta = LIBMTP_new_file_t();
    meta->filename = strdup(remote);
    meta->filesize = (uint64_t)st.st_size;
    /* The watch keys off the .prg extension, not the MTP filetype. */
    meta->filetype = LIBMTP_FILETYPE_UNKNOWN;
    meta->parent_id = parent;
    meta->storage_id = storage_of(dev);

    printf("Sending %s -> folder %u as %s (%lld bytes)\n",
           local, parent, remote, (long long)st.st_size);
    int rc = LIBMTP_Send_File_From_File(dev, local, meta, progress, NULL);
    fprintf(stderr, "\n");
    if (rc != 0) {
        printf("FAILED (rc=%d)\n", rc);
        LIBMTP_Dump_Errorstack(dev);
        LIBMTP_Clear_Errorstack(dev);
    } else {
        printf("OK, object id %u\n", meta->item_id);
    }
    LIBMTP_destroy_file_t(meta);
    return rc != 0;
}

static int cmd_get(LIBMTP_mtpdevice_t *dev, const char *id, const char *local) {
    uint32_t oid = (uint32_t)strtoul(id, NULL, 10);
    int rc = LIBMTP_Get_File_To_File(dev, oid, local, progress, NULL);
    fprintf(stderr, "\n");
    if (rc != 0) {
        LIBMTP_Dump_Errorstack(dev);
        LIBMTP_Clear_Errorstack(dev);
    } else {
        printf("Wrote %s\n", local);
    }
    return rc != 0;
}

static void usage(void) {
    fprintf(stderr,
        "usage:\n"
        "  mtpsend resolve <path>                        print folder id\n"
        "  mtpsend list    <path|folderid>               list a folder\n"
        "  mtpsend send    <local> <path|folderid> <name>  upload, replacing by name\n"
        "  mtpsend get     <objectid> <local>            download an object\n"
        "\n"
        "<path> is slash separated from the storage root, e.g. GARMIN/Apps\n");
}

int main(int argc, char **argv) {
    if (argc < 2) { usage(); return 2; }
    LIBMTP_Init();
    LIBMTP_mtpdevice_t *dev = open_device();
    if (!dev) return 1;

    int rc = 2;
    if (!strcmp(argv[1], "resolve") && argc == 3) {
        uint32_t id = resolve_folder(dev, argv[2]);
        if (id) { printf("%u\n", id); rc = 0; } else rc = 1;
    } else if (!strcmp(argv[1], "list") && argc == 3) {
        rc = cmd_list(dev, argv[2]);
    } else if (!strcmp(argv[1], "send") && argc == 5) {
        rc = cmd_send(dev, argv[2], argv[3], argv[4]);
    } else if (!strcmp(argv[1], "get") && argc == 4) {
        rc = cmd_get(dev, argv[2], argv[3]);
    } else {
        usage();
    }

    LIBMTP_Release_Device(dev);
    return rc;
}
