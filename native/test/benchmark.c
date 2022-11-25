#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>
#include "benchmark.h"

static inline void dart_post_pointer(void *pointer, Dart_Port port)
{
	Dart_CObject dart_object;
	dart_object.type = Dart_CObject_kInt64;
	dart_object.value.as_int64 = (int64_t)pointer;
	Dart_PostCObject(port, &dart_object);
};

struct initialization_args
{
	uint32_t count;
	Dart_Port port;
};

struct benchmark
{
	pthread_t main_thread_id;
	pthread_mutex_t completion_mutex;
	pthread_cond_t completion_condition;
	bool completed;
};

struct message
{
	char *value;
};

static struct benchmark instance;

void *function(void *input)
{
	printf("Benchmark started\n");
	struct initialization_args *args = (struct initialization_args *)input;
	struct message *message = malloc(sizeof(struct message));
	message->value = "benchmark";
	for (size_t i = 0; i < args->count; i++)
	{
		dart_post_pointer(message, args->port);
	}
	pthread_mutex_lock(&instance.completion_mutex);
	instance.completed = true;
	pthread_cond_signal(&instance.completion_condition);
	pthread_mutex_unlock(&instance.completion_mutex);
	return NULL;
}

void dart_run_benchmark(uint32_t count, Dart_Port port)
{
	struct initialization_args *args = malloc(sizeof(struct initialization_args));
	args->count = count;
	args->port = port;
	pthread_create(&instance.main_thread_id, NULL, function, args);
	pthread_mutex_lock(&instance.completion_mutex);
	while (!instance.completed)
		pthread_cond_wait(&instance.completion_condition, &instance.completion_mutex);
	pthread_mutex_unlock(&instance.completion_mutex);
}
