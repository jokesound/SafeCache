#include <sys/stat.h>
#include <fcntl.h>
#include <dirent.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

static int clean_fd(int dirfd) {
    int dupfd = dup(dirfd);
    if (dupfd < 0) return 0;
    DIR *dir = fdopendir(dupfd);
    if (!dir) { close(dupfd); return 0; }
    int ok = 1;
    struct dirent *e;
    while ((e = readdir(dir))) {
        const char *name = e->d_name;
        if (!strcmp(name, ".") || !strcmp(name, "..")) continue;
        struct stat st;
        if (fstatat(dirfd, name, &st, AT_SYMLINK_NOFOLLOW) != 0) { ok = 0; continue; }
        if (S_ISLNK(st.st_mode)) { ok = 0; continue; }
        if (S_ISDIR(st.st_mode)) {
            int child = openat(dirfd, name, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
            if (child < 0) { ok = 0; continue; }
            int child_ok = clean_fd(child);
            close(child);
            if (child_ok && unlinkat(dirfd, name, AT_REMOVEDIR) != 0 && errno != ENOENT && errno != ENOTEMPTY) ok = 0;
            else if (!child_ok) ok = 0;
        } else if (S_ISREG(st.st_mode)) {
            if (unlinkat(dirfd, name, 0) != 0 && errno != ENOENT) ok = 0;
        } else {
            ok = 0;
        }
    }
    closedir(dir);
    return ok;
}

static void write_file(const char *path) {
    int fd = open(path, O_CREAT | O_WRONLY | O_TRUNC, 0600);
    if (fd < 0) { perror("open"); exit(2); }
    write(fd, "safe", 4);
    close(fd);
}

int main(void) {
    char templ[] = "/tmp/safecache-test-XXXXXX";
    char *root = mkdtemp(templ);
    if (!root) return 2;

    char cache[PATH_MAX], nested[PATH_MAX], outside[PATH_MAX], insideFile[PATH_MAX], nestedFile[PATH_MAX], protectedFile[PATH_MAX], linkPath[PATH_MAX];
    snprintf(cache, sizeof(cache), "%s/cache", root);
    snprintf(nested, sizeof(nested), "%s/cache/nested", root);
    snprintf(outside, sizeof(outside), "%s/outside", root);
    snprintf(insideFile, sizeof(insideFile), "%s/cache/cache.bin", root);
    snprintf(nestedFile, sizeof(nestedFile), "%s/cache/nested/cache2.bin", root);
    snprintf(protectedFile, sizeof(protectedFile), "%s/outside/KEEP.txt", root);
    snprintf(linkPath, sizeof(linkPath), "%s/cache/escape", root);
    mkdir(cache, 0700); mkdir(nested, 0700); mkdir(outside, 0700);
    write_file(insideFile); write_file(nestedFile); write_file(protectedFile);
    if (symlink(outside, linkPath) != 0) return 3;

    int fd = open(cache, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (fd < 0) return 4;
    clean_fd(fd);
    close(fd);

    if (access(insideFile, F_OK) == 0) { fprintf(stderr, "FAIL: cache file remained\n"); return 10; }
    if (access(nestedFile, F_OK) == 0) { fprintf(stderr, "FAIL: nested cache file remained\n"); return 11; }
    if (access(protectedFile, F_OK) != 0) { fprintf(stderr, "FAIL: followed symlink outside cache\n"); return 12; }
    struct stat lst;
    if (lstat(linkPath, &lst) != 0 || !S_ISLNK(lst.st_mode)) { fprintf(stderr, "FAIL: symlink should be left untouched\n"); return 13; }

    printf("PASS: regular cache files removed; symlink target untouched.\n");
    return 0;
}
