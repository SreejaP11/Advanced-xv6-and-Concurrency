#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>
#include <time.h>

#define MAX_USERS 1000

typedef struct {
    int user_id;
    int file_id;
    char operation[10];
    int request_time;
} Request;

typedef struct {
    int is_deleted;
    int read_count;
    sem_t lock;   // Controls read counter
    sem_t write_lock;        // Allows only one WRITE at a time
    sem_t delete_lock;       // Allows DELETE only when no readers/writers
} File;

// Parameters
int read_time, write_time, delete_time;
int num_files, max_concurrent, patience_time;
Request requests[MAX_USERS];
int num_requests = 0;

File* files = NULL;
pthread_mutex_t print_lock;

// Helper function to print with a delay
void print_with_timestamp(const char *message, const char *color) {
    pthread_mutex_lock(&print_lock);
    printf("%s%s%s\n", color, message, "\033[0m");
    pthread_mutex_unlock(&print_lock);
}

// Simulate file operations for each request
void *handle_request(void *arg) {
    Request *request = (Request *)arg;
    int user_id = request->user_id;
    int file_id = request->file_id;
    char operation[10];
    strcpy(operation, request->operation);
    int request_time = request->request_time;
    
    sleep(request_time);  // Simulate waiting until the request time
    char message[100];
    snprintf(message, sizeof(message), "User %d has made request for performing %s on file %d at %d seconds", user_id, operation, file_id + 1, request_time);
    print_with_timestamp(message, "\033[33m");

    // Wait 1 second before starting to process the request
    sleep(1);
    File *file = &files[file_id];
    int wait_time = 1;

    // Retry if patience time allows, otherwise cancel
    while (wait_time < patience_time) {
        if (strcmp(operation, "READ") == 0) {
            sem_wait(&file->lock);
            if (file->is_deleted) {
                snprintf(message, sizeof(message), "LAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested.", user_id, request_time + wait_time);
                print_with_timestamp(message, "\033[37m");
                sem_post(&file->lock);
                return NULL;
            }
            file->read_count++;
            if (file->read_count == 1) {
                sem_wait(&file->delete_lock); // First reader locks delete
            }
            sem_post(&file->lock);

            snprintf(message, sizeof(message), "LAZY has taken up the request of User %d at %d seconds", user_id, request_time + wait_time);
            print_with_timestamp(message, "\033[35m");
            sleep(read_time);
            snprintf(message, sizeof(message), "The request for User %d was completed at %d seconds ", user_id, request_time + wait_time + read_time);
            print_with_timestamp(message, "\033[32m");

            sem_wait(&file->lock);
            file->read_count--;
            if (file->read_count == 0) {
                sem_post(&file->delete_lock); // Last reader unlocks delete
            }
            sem_post(&file->lock);
            break;
        } else if (strcmp(operation, "WRITE") == 0) {
            sem_wait(&file->write_lock);
            sem_wait(&file->lock);
            if (file->is_deleted) {
                snprintf(message, sizeof(message), "LAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested.", user_id, request_time + wait_time);
                print_with_timestamp(message, "\033[37m");
                sem_post(&file->lock);
                sem_post(&file->write_lock);
                return NULL;
            }
            sem_post(&file->lock);

            snprintf(message, sizeof(message), "LAZY has taken up the request of User %d at %d seconds", user_id, request_time + wait_time);
            print_with_timestamp(message, "\033[35m");
            sleep(write_time);
            snprintf(message, sizeof(message), "The request for User %d was completed at %d seconds ", user_id, request_time + wait_time + write_time);
            print_with_timestamp(message, "\033[32m");

            sem_post(&file->write_lock);
            break;
        } else if (strcmp(operation, "DELETE") == 0) {
            if (sem_trywait(&file->delete_lock) == 0) {
                sem_wait(&file->write_lock);
                sem_wait(&file->lock);
                if (file->is_deleted) {
                    snprintf(message, sizeof(message), "LAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested.", user_id, request_time + wait_time);
                    print_with_timestamp(message, "\033[37m");
                    sem_post(&file->lock);
                    sem_post(&file->write_lock);
                    sem_post(&file->delete_lock);
                    return NULL;
                }
                file->is_deleted = 1;
                sem_post(&file->lock);

                snprintf(message, sizeof(message), "LAZY has taken up the request of User %d at %d seconds", user_id, request_time + wait_time);
                print_with_timestamp(message, "\033[35m");
                sleep(delete_time);
                snprintf(message, sizeof(message), "The request for User %d was completed at %d seconds ", user_id, request_time + wait_time + delete_time);
                print_with_timestamp(message, "\033[32m");

                sem_post(&file->write_lock);
                sem_post(&file->delete_lock);
                break;
            }
        }
        sleep(1);  
        wait_time++;
    }

    if (wait_time >= patience_time) {
        snprintf(message, sizeof(message), "User %d canceled the request due to no response at %d seconds", user_id, request_time + wait_time);
        print_with_timestamp(message, "\033[31m");
    }

    return NULL;
}

// Initialize files and read requests
void init_files() {
    for (int i = 0; i < num_files; i++) {
        files[i].is_deleted = 0;
        files[i].read_count = 0;
        sem_init(&files[i].lock, 0, max_concurrent);
        sem_init(&files[i].write_lock, 0, 1);
        sem_init(&files[i].delete_lock, 0, 1);
    }
}

// Parse input and start request threads
void start_simulation() {
    pthread_t threads[MAX_USERS];
    
    for (int i = 0; i < num_requests; i++) {
        pthread_create(&threads[i], NULL, handle_request, (void *)&requests[i]);
    }
    
    for (int i = 0; i < num_requests; i++) {
        pthread_join(threads[i], NULL);
    }

    printf("LAZY has no more pending requests and is going back to sleep!\n");
}

int main() {
    scanf("%d %d %d", &read_time, &write_time, &delete_time);
    scanf("%d %d %d", &num_files, &max_concurrent, &patience_time);
    files = malloc(num_files * sizeof(File));
    init_files();

    int user_id, file_id, request_time;
    char operation[10];
    while (scanf("%d %d %s %d", &user_id, &file_id, operation, &request_time) == 4) {
        requests[num_requests++] = (Request){user_id, file_id - 1, "", request_time};
        strcpy(requests[num_requests - 1].operation, operation);
    }

    printf("LAZY has woken up!\n");
    start_simulation();

    return 0;
}