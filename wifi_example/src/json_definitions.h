#ifndef PICO_EXAMPLE_JSON_DEFINITIONS_H_
#define PICO_EXAMPLE_JSON_DEFINITIONS_H_

#include <zephyr/data/json.h>

struct json_example_object {
	const char *title;
	const char *body;
	int id;
	int userId;
};

static const struct json_obj_descr json_example_object_descr[] = {
	JSON_OBJ_DESCR_PRIM(struct json_example_object, title, JSON_TOK_STRING),
	JSON_OBJ_DESCR_PRIM(struct json_example_object, body, JSON_TOK_STRING),
	JSON_OBJ_DESCR_PRIM(struct json_example_object, id, JSON_TOK_NUMBER),
	JSON_OBJ_DESCR_PRIM(struct json_example_object, userId, JSON_TOK_NUMBER),
};

struct json_example_payload {
	const char *title;
	const char *body;
    int userId;
};

static const struct json_obj_descr json_example_payload_descr[] = {
	JSON_OBJ_DESCR_PRIM(struct json_example_payload, title, JSON_TOK_STRING),
	JSON_OBJ_DESCR_PRIM(struct json_example_payload, body, JSON_TOK_STRING),
	JSON_OBJ_DESCR_PRIM(struct json_example_payload, userId, JSON_TOK_NUMBER),
};

#endif // PICO_JSON_DEFINITIONS_H_
