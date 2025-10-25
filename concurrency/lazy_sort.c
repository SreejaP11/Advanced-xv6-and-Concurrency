#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

#define MAX_FILE_NAME_LENGTH 128
#define THRESHOLD 42

typedef struct {
    char name[MAX_FILE_NAME_LENGTH];
    int id;
    char timestamp[20];
} File;

File *files;
int num_files;
char sort_column[10];

typedef struct {
    int start_idx;
    int end_idx;
} ThreadArgs;

int compare_by_name(const void *a, const void *b) {
    return strcmp(((File*)a)->name, ((File*)b)->name);
}

int compare_by_id(const void *a, const void *b) {
    return ((File*)a)->id - ((File*)b)->id;
}

int compare_by_timestamp(const void *a, const void *b) {
    return strcmp(((File*)a)->timestamp, ((File*)b)->timestamp);
}

void count_sort(File *arr, int n, int (*compare)(const void *, const void *)) {
    qsort(arr, n, sizeof(File), compare);
}

void merge(File *arr, int left, int mid, int right, int (*compare)(const void *, const void *)) {
    int n1 = mid - left + 1;
    int n2 = right - mid;
    File *L = malloc(n1 * sizeof(File));
    File *R = malloc(n2 * sizeof(File));

    for (int i = 0; i < n1; i++) L[i] = arr[left + i];
    for (int i = 0; i < n2; i++) R[i] = arr[mid + 1 + i];

    int i = 0, j = 0, k = left;
    while (i < n1 && j < n2) {
        if (compare(&L[i], &R[j]) <= 0) {
            arr[k++] = L[i++];
        } else {
            arr[k++] = R[j++];
        }
    }

    while (i < n1) arr[k++] = L[i++];
    while (j < n2) arr[k++] = R[j++];

    free(L);
    free(R);
}

void merge_sort(File *arr, int left, int right, int (*compare)(const void *, const void *)) {
    if (left < right) {
        int mid = left + (right - left) / 2;
        merge_sort(arr, left, mid, compare);
        merge_sort(arr, mid + 1, right, compare);
        merge(arr, left, mid, right, compare);
    }
}

void* thread_merge_sort(void *args) {
    ThreadArgs *t_args = (ThreadArgs *)args;
    int left = t_args->start_idx;
    int right = t_args->end_idx;
    free(t_args);

    if (right - left < 2) {
        qsort(&files[left], right - left + 1, sizeof(File), compare_by_name);
    } else {
        merge_sort(files, left, right, compare_by_name);
    }
    return NULL;
}

void sort_files() {
    int (*compare)(const void *, const void *);
    if (strcmp(sort_column, "Name") == 0) {
        compare = compare_by_name;
    } else if (strcmp(sort_column, "ID") == 0) {
        compare = compare_by_id;
    } else if (strcmp(sort_column, "Timestamp") == 0) {
        compare = compare_by_timestamp;
    }

    if (num_files < THRESHOLD) {
        count_sort(files, num_files, compare);
    } else {
        pthread_t threads[4];
        int chunk_size = num_files / 4;

        for (int i = 0; i < 4; i++) {
            ThreadArgs *args = malloc(sizeof(ThreadArgs));
            args->start_idx = i * chunk_size;
            args->end_idx = (i == 3) ? num_files - 1 : (i + 1) * chunk_size - 1;
            pthread_create(&threads[i], NULL, thread_merge_sort, args);
        }

        for (int i = 0; i < 4; i++) {
            pthread_join(threads[i], NULL);
        }
    }

    printf("%s\n", sort_column);
    for (int i = 0; i < num_files; i++) {
        printf("%s %d %s\n", files[i].name, files[i].id, files[i].timestamp);
    }
}

int main() {
    scanf("%d", &num_files);
    files = malloc(num_files * sizeof(File));

    for (int i = 0; i < num_files; i++) {
        scanf("%s %d %s", files[i].name, &files[i].id, files[i].timestamp);
    }

    scanf("%s", sort_column);

    sort_files();

    free(files);
    return 0;
}
