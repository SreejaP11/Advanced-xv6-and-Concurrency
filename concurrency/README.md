# concurrency

This document provides a comprehensive overview of the concurrency and sorting tasks implemented for the LAZY Corp simulation project. The tasks were developed to simulate real-world scenarios within a file management system and a distributed sorting system, employing various concurrency mechanisms to handle tasks efficiently.

## 1. LAZY Read-Write Simulation

The LAZY Read-Write task simulates a file manager handling READ, WRITE, and DELETE operations with concurrent user requests. The system is designed to work under load, managing multiple user requests using threads, locks, condition variables, and semaphores.

### Implementation Details

- **Operations**: Each file operation (READ, WRITE, DELETE) has specified processing times.
- **Concurrency Limits**: A maximum number of users can access a file simultaneously, beyond which additional requests are queued or dropped.
- **Request Cancellation**: Users can cancel their requests if processing does not commence within a pre-defined time limit.

### Simulation

- **Processing Delays**: The system introduces a delay before starting the processing of requests.
- **Resource Conflicts**: Handles conflicts where multiple operations cannot be processed simultaneously on the same file.
- **Input and Output**: The system reads operations from an input format and outputs the sequence of actions in the console, indicating the operation's start, processing, and completion.

## 2. LAZY Sorting System

The LAZY Sorting System is designed to dynamically select a sorting algorithm based on the number of files to process. For smaller datasets, a simple Count Sort is employed, whereas larger datasets trigger a more complex Merge Sort to ensure efficiency at scale.

### Sorting

- **Distributed Count Sort**: Used for fewer than 42 files, focusing on minimal resource usage and straightforward implementation.
- **Distributed Merge Sort**: Applied to more extensive datasets, utilizing multiple threads to handle the increased load effectively.

### Implementation

- **Task Distribution**: The system partitions the sorting task across multiple threads, simulating a distributed environment where each thread represents a node.
- **Resource Management**: Emphasizes efficient resource utilization, activating nodes only when necessary and minimizing idle time.

## Execution and Testing

The project includes scripts for executing and testing both the LAZY Read-Write Simulation and the LAZY Sorting System. Each component can be tested independently, providing detailed logs of each operation and its outcome.


## Setup and Execution

### Requirements
- GCC Compiler
- POSIX Threads Library

### Compilation Instructions

To compile the `file_manager` and `lazy_sort` programs, navigate to the `concurrency` directory and use the following commands:

```bash
gcc -o file_manager file_manager.c -lpthread
gcc -o lazy_sort lazy_sort.c -lpthread
