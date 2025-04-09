#ifndef PICO_EXAMPLE_JSON_DEFINITIONS_H_
#define PICO_EXAMPLE_JSON_DEFINITIONS_H_

#include <zephyr/data/json.h>

struct placeholder_post {
	const char *title;
	const char *body;
	int id;
	int userId;
};

static const struct json_obj_descr placeholder_post_descr[] = {
	JSON_OBJ_DESCR_PRIM(struct placeholder_post, title, JSON_TOK_STRING),
	JSON_OBJ_DESCR_PRIM(struct placeholder_post, body, JSON_TOK_STRING),
	JSON_OBJ_DESCR_PRIM(struct placeholder_post, id, JSON_TOK_NUMBER),
	JSON_OBJ_DESCR_PRIM(struct placeholder_post, userId, JSON_TOK_NUMBER),
};

#endif // PICO_JSON_DEFINITIONS_H_
