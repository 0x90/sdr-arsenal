#include <stdio.h>
#include <sys/types.h>
#include <Rectangle.h>
/* Rectangle ASN.1 type */
/* Write the encoded output into some FILE stream. */
static int write_out(const void *buffer, size_t size, void *app_key) {
FILE *out_fp = app_key;
size_t wrote = fwrite(buffer, 1, size, out_fp);
return (wrote == size) ? 0 : -1;
}
int main(int ac, char **av) {
Rectangle_t *rectangle; /* Type to encode */
asn_enc_rval_t ec;
/* Encoder return value
*/

/* Allocate the Rectangle_t */
rectangle = calloc(1, sizeof(Rectangle_t)); /* not malloc! */
if(!rectangle) {
perror("calloc() failed");
exit(1);
}
/* Initialize the Rectangle members */
rectangle->height = 42; /* any random value */
rectangle->width = 23; /* any random value */
/* BER encode the data if filename is given */
if(ac < 2) {
fprintf(stderr, "Specify filename for BER output\n");
} else {
const char *filename = av[1];
FILE *fp = fopen(filename, "wb");
/* for BER output */
if(!fp) {
perror(filename);
exit(1);
}
/* Encode the Rectangle type as BER (DER) */
ec = der_encode(&asn_DEF_Rectangle, rectangle, write_out, fp);
fclose(fp);
if(ec.encoded == -1) {
fprintf(stderr, "Could not encode Rectangle (at %s)\n",
ec.failed_type ? ec.failed_type->name : "unknown");
exit(1);
} else {
fprintf(stderr, "Created %s with BER encoded Rectangle\n", filename);
}
}
/* Also print the constructed Rectangle XER encoded (XML) */
xer_fprint(stdout, &asn_DEF_Rectangle, rectangle);
return 0; /* Encoding finished successfully */
}

