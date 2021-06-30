// Stuff from postgres_ext.h

Oid :: u32;

#load "pq_types.jai";

InvalidOid : Oid : 0;

PG_DIAG_SEVERITY :: #char "S";
PG_DIAG_SEVERITY_NONLOCALIZED :: #char "V";
PG_DIAG_SQLSTATE :: #char "C";
PG_DIAG_MESSAGE_PRIMARY :: #char "M";
PG_DIAG_MESSAGE_DETAIL :: #char "D";
PG_DIAG_MESSAGE_HINT :: #char "H";
PG_DIAG_STATEMENT_POSITION :: #char "P";
PG_DIAG_INTERNAL_POSITION :: #char "p";
PG_DIAG_INTERNAL_QUERY :: #char "q";
PG_DIAG_CONTEXT :: #char "W";
PG_DIAG_SCHEMA_NAME :: #char "s";
PG_DIAG_TABLE_NAME :: #char "t";
PG_DIAG_COLUMN_NAME :: #char "c";
PG_DIAG_DATATYPE_NAME :: #char "d";
PG_DIAG_CONSTRAINT_NAME :: #char "n";
PG_DIAG_SOURCE_FILE :: #char "F";
PG_DIAG_SOURCE_LINE :: #char "L";
PG_DIAG_SOURCE_FUNCTION :: #char "R";

// Stuff from libpq-fe.h

// Option flags for PQcopyResult
PG_COPYRES_ATTRS :: 0x01;
PG_COPYRES_TUPLES :: 0x02;	/* Implies PG_COPYRES_ATTRS */
PG_COPYRES_EVENTS :: 0x04;
PG_COPYRES_NOTICEHOOKS :: 0x08;

/* Application-visible enum types */
ConnStatusType :: enum u32 {
	CONNECTION_OK :: 0;
	CONNECTION_BAD;

	// Non-blocking mode only below here
	/*
	 * The existence of these should never be relied upon - they should only
	 * be used for user feedback or similar purposes.
	 */
	CONNECTION_STARTED;			/* Waiting for connection to be made.  */
	CONNECTION_MADE;			/* Connection OK; waiting to send.     */
	CONNECTION_AWAITING_RESPONSE;	/* Waiting for a response from the
									 * postmaster.        */
	CONNECTION_AUTH_OK;			/* Received authentication; waiting for
								 * backend startup. */
	CONNECTION_SETENV;			/* Negotiating environment. */
	CONNECTION_SSL_STARTUP;		/* Negotiating SSL. */
	CONNECTION_NEEDED;			/* Internal state: connect() needed */
	CONNECTION_CHECK_WRITABLE;	/* Check if we could make a writable
								 * connection. */
	CONNECTION_CONSUME;			/* Wait for any pending message and consume
								 * them. */
	CONNECTION_GSS_STARTUP;		/* Negotiating GSSAPI. */
	CONNECTION_CHECK_TARGET;		/* Check if we have a proper target connection */
}

PostgresPollingStatusType :: enum u32 {
	PGRES_POLLING_FAILED :: 0;
	PGRES_POLLING_READING;		/* These two indicate that one may	  */
	PGRES_POLLING_WRITING;		/* use select before polling again.   */
	PGRES_POLLING_OK;
	PGRES_POLLING_ACTIVE;		/* unused; keep for awhile for backwards
								 * compatibility */
}

ExecStatusType :: enum u32 {
	PGRES_EMPTY_QUERY :: 0;		/* empty query string was executed */
	PGRES_COMMAND_OK;			/* a query command that doesn't return
								 * anything was executed properly by the
								 * backend */
	PGRES_TUPLES_OK;			/* a query command that returns tuples was
								 * executed properly by the backend, PGresult
								 * contains the result tuples */
	PGRES_COPY_OUT;				/* Copy Out data transfer in progress */
	PGRES_COPY_IN;				/* Copy In data transfer in progress */
	PGRES_BAD_RESPONSE;			/* an unexpected response was recv'd from the
								 * backend */
	PGRES_NONFATAL_ERROR;		/* notice or warning message */
	PGRES_FATAL_ERROR;			/* query failed */
	PGRES_COPY_BOTH;			/* Copy In/Out data transfer in progress */
	PGRES_SINGLE_TUPLE;			/* single tuple from larger resultset */
}

PGTransactionStatusType :: enum u32 {
	PQTRANS_IDLE;				/* connection idle */
	PQTRANS_ACTIVE;				/* command in progress */
	PQTRANS_INTRANS;			/* idle, within transaction block */
	PQTRANS_INERROR;			/* idle, within failed transaction */
	PQTRANS_UNKNOWN;			/* cannot determine status */
}

PGVerbosity :: enum u32 {
	PQERRORS_TERSE;				/* single-line error messages */
	PQERRORS_DEFAULT;			/* recommended style */
	PQERRORS_VERBOSE;			/* all the facts, ma'am */
	PQERRORS_SQLSTATE;			/* only error severity and SQLSTATE code */
}

PGContextVisibility :: enum u32 {
	PQSHOW_CONTEXT_NEVER;		/* never show CONTEXT field */
	PQSHOW_CONTEXT_ERRORS;		/* show CONTEXT for errors only (default) */
	PQSHOW_CONTEXT_ALWAYS;		/* always show CONTEXT field */
}

/*
 * PGPing - The ordering of this enum should not be altered because the
 * values are exposed externally via pg_isready.
 */

PGPing :: enum u32 {
	PQPING_OK;					/* server is accepting connections */
	PQPING_REJECT;				/* server is alive but rejecting connections */
	PQPING_NO_RESPONSE;			/* could not establish connection */
	PQPING_NO_ATTEMPT;			/* connection not attempted (bad params) */
}

/* PGconn encapsulates a connection to the backend.
 * The contents of this struct are not supposed to be known to applications.
 */
PGconn :: struct {}

/* PGresult encapsulates the result of a query (or more precisely, of a single
 * SQL command --- a query string given to PQsendQuery can contain multiple
 * commands and thus return multiple PGresult objects).
 * The contents of this struct are not supposed to be known to applications.
 */
PGresult :: struct {}

/* PGcancel encapsulates the information needed to cancel a running
 * query on an existing connection.
 * The contents of this struct are not supposed to be known to applications.
 */
PGcancel :: struct {}

/* PGnotify represents the occurrence of a NOTIFY message.
 * Ideally this would be an opaque typedef, but it's so simple that it's
 * unlikely to change.
 * NOTE: in Postgres 6.4 and later, the be_pid is the notifying backend's,
 * whereas in earlier versions it was always your own backend's PID.
 */
PGnotify :: struct {
	relname: *u8;		/* notification condition name */
	be_pid: s32;			/* process ID of notifying server process */
	extra: *u8;			/* notification parameter */
	/* Fields below here are private to libpq; apps should not use 'em */
	next: *PGnotify;		/* list link */
}

/* Function types for notice-handling callbacks */
PQnoticeReceiver :: #type (arg: *void, res: *PGresult) -> void #c_call;
PQnoticeProcessor :: #type (arg: *void, message: *u8) -> void #c_call;

/* Print options for PQprint() */
pqbool :: u8;

QprintOpt :: struct {
	header: pqbool;			/* print output field headings and row count */
	align: pqbool;			/* fill align the fields */
	standard: pqbool;		/* old brain dead format */
	html3: pqbool;			/* output html tables */
	expanded: pqbool;		/* expand tables */
	pager: pqbool;			/* use pager for output if needed */
	fieldSep: *u8;		/* field separator */
	tableOpt: *u8;		/* insert to HTML <table ...> */
	caption: *u8;		/* HTML <caption> */
	fieldName: **u8;		/* null terminated array of replacement field
								 * names */
}

/* ----------------
 * Structure for the conninfo parameter definitions returned by PQconndefaults
 * or PQconninfoParse.
 *
 * All fields except "val" point at static strings which must not be altered.
 * "val" is either NULL or a malloc'd current-value string.  PQconninfoFree()
 * will release both the val strings and the PQconninfoOption array itself.
 * ----------------
 */
PQconninfoOption :: struct {
	keyword: *u8;		/* The keyword of the option			*/
	envvar: *u8;			/* Fallback environment variable name	*/
	compiled: *u8;		/* Fallback compiled in default value	*/
	val: *u8;			/* Option's current value, or NULL		 */
	label: *u8;			/* Label for field in connect dialog	*/
	dispchar: *u8;		/* Indicates how to display this field in a
								 * connect dialog. Values are: "" Display
								 * entered value as is "*" Password field -
								 * hide value "D"  Debug option - don't show
								 * by default */
	dispsize: s32;		/* Field size in characters for dialog	*/
}

/* ----------------
 * PQArgBlock -- structure for PQfn() arguments
 * ----------------
 */
PQArgBlock :: struct {
	len: s32;
	isint: s32;
	u: union {
		ptr: *s32;		/* can't use void (dec compiler barfs)	 */
		integer: s32;
	};
}

/* ----------------
 * PGresAttDesc -- Data about a single attribute (column) of a query result
 * ----------------
 */
PGresAttDesc :: struct {
	name: *u8;			/* column name */
	tableid: Oid;		/* source table, if known */
	columnid: s32;		/* source column, if known */
	format: s32;			/* format code for value (text/binary) */
	typid: Oid;			/* type id */
	typlen: s32;			/* type size */
	atttypmod: s32;		/* type-specific modifier info */
}

/* ----------------
 * Exported functions of libpq
 * ----------------
 */

/* ===	in fe-connect.c === */

/* make a new client connection to the backend */
/* Asynchronous (non-blocking) */
PQconnectStart :: (conninfo: *u8) -> *PGconn #foreign libpq;
PQconnectStartParams :: (keywords: **u8, values: **u8, expand_dbname: s32) -> *PGconn #foreign libpq;
PQconnectPoll :: (conn: *PGconn) -> PostgresPollingStatusType #foreign libpq;

// /* Synchronous (blocking) */
// extern PGconn *PQconnectdb(const char *conninfo);
// extern PGconn *PQconnectdbParams(const char *const *keywords,
// 								 const char *const *values, s32 expand_dbname);
// extern PGconn *PQsetdbLogin(const char *pghost, const char *pgport,
// 							const char *pgoptions, const char *pgtty,
// 							const char *dbName,
// 							const char *login, const char *pwd);

// #define PQsetdb(M_PGHOST,M_PGPORT,M_PGOPT,M_PGTTY,M_DBNAME)  \
// 	PQsetdbLogin(M_PGHOST, M_PGPORT, M_PGOPT, M_PGTTY, M_DBNAME, NULL, NULL)

/* close the current connection and free the PGconn data structure */
PQfinish :: (conn: *PGconn) -> void #foreign libpq;

// /* get info about connection options known to PQconnectdb */
// extern PQconninfoOption *PQconndefaults(void);

// /* parse connection options in same way as PQconnectdb */
// extern PQconninfoOption *PQconninfoParse(const char *conninfo, char **errmsg);

// /* return the connection options used by a live connection */
// extern PQconninfoOption *PQconninfo(PGconn *conn);

// /* free the data structure returned by PQconndefaults() or PQconninfoParse() */
// extern void PQconninfoFree(PQconninfoOption *connOptions);

// /*
//  * close the current connection and reestablish a new one with the same
//  * parameters
//  */
// /* Asynchronous (non-blocking) */
// extern s32	PQresetStart(PGconn *conn);
// extern PostgresPollingStatusType PQresetPoll(PGconn *conn);

// /* Synchronous (blocking) */
// extern void PQreset(PGconn *conn);

// /* request a cancel structure */
// extern PGcancel *PQgetCancel(PGconn *conn);

// /* free a cancel structure */
// extern void PQfreeCancel(PGcancel *cancel);

// /* issue a cancel request */
// extern s32	PQcancel(PGcancel *cancel, char *errbuf, s32 errbufsize);

// /* Accessor functions for PGconn objects */
// extern char *PQdb(const PGconn *conn);
// extern char *PQuser(const PGconn *conn);
// extern char *PQpass(const PGconn *conn);
// extern char *PQhost(const PGconn *conn);
// extern char *PQhostaddr(const PGconn *conn);
// extern char *PQport(const PGconn *conn);
// extern char *PQtty(const PGconn *conn);
// extern char *PQoptions(const PGconn *conn);
PQstatus :: (conn: *PGconn) -> ConnStatusType #foreign libpq;
// extern PGTransactionStatusType PQtransactionStatus(const PGconn *conn);
// extern const char *PQparameterStatus(const PGconn *conn,
// 									 const char *paramName);
// extern s32	PQprotocolVersion(const PGconn *conn);
// extern s32	PQserverVersion(const PGconn *conn);
// extern char *PQerrorMessage(const PGconn *conn);
// extern s32	PQsocket(const PGconn *conn);
// extern s32	PQbackendPID(const PGconn *conn);
// extern s32	PQconnectionNeedsPassword(const PGconn *conn);
// extern s32	PQconnectionUsedPassword(const PGconn *conn);
// extern s32	PQclientEncoding(const PGconn *conn);
// extern s32	PQsetClientEncoding(PGconn *conn, const char *encoding);

// /* SSL information functions */
// extern s32	PQsslInUse(PGconn *conn);
// extern void *PQsslStruct(PGconn *conn, const char *struct_name);
// extern const char *PQsslAttribute(PGconn *conn, const char *attribute_name);
// extern const char *const *PQsslAttributeNames(PGconn *conn);

// /* Get the OpenSSL structure associated with a connection. Returns NULL for
//  * unencrypted connections or if any other TLS library is in use. */
// extern void *PQgetssl(PGconn *conn);

// /* Tell libpq whether it needs to initialize OpenSSL */
// extern void PQinitSSL(s32 do_init);

// /* More detailed way to tell libpq whether it needs to initialize OpenSSL */
// extern void PQinitOpenSSL(s32 do_ssl, s32 do_crypto);

// /* Return true if GSSAPI encryption is in use */
// extern s32	PQgssEncInUse(PGconn *conn);

// /* Returns GSSAPI context if GSSAPI is in use */
// extern void *PQgetgssctx(PGconn *conn);

/* Set verbosity for PQerrorMessage and PQresultErrorMessage */
PQsetErrorVerbosity :: (conn: *PGconn, verbosity: PGVerbosity) -> PGVerbosity #foreign libpq;

// /* Set CONTEXT visibility for PQerrorMessage and PQresultErrorMessage */
PQsetErrorContextVisibility :: (conn: *PGconn, show_context: PGContextVisibility) -> PGContextVisibility #foreign libpq;

// /* Enable/disable tracing */
// extern void PQtrace(PGconn *conn, FILE *debug_port);
// extern void PQuntrace(PGconn *conn);

// /* Override default notice handling routines */
// extern PQnoticeReceiver PQsetNoticeReceiver(PGconn *conn,
// 											PQnoticeReceiver proc,
// 											void *arg);
// extern PQnoticeProcessor PQsetNoticeProcessor(PGconn *conn,
// 											  PQnoticeProcessor proc,
// 											  void *arg);

// /*
//  *	   Used to set callback that prevents concurrent access to
//  *	   non-thread safe functions that libpq needs.
//  *	   The default implementation uses a libpq internal mutex.
//  *	   Only required for multithreaded apps that use kerberos
//  *	   both within their app and for postgresql connections.
//  */
// typedef void (*pgthreadlock_t) (s32 acquire);

// extern pgthreadlock_t PQregisterThreadLock(pgthreadlock_t newhandler);

// /* === in fe-exec.c === */

// /* Simple synchronous query */
PQexec :: (conn: *PGconn, query: *u8) -> *PGresult #foreign libpq;

PQexecParams :: (conn: *PGconn, command: *u8, nParams: s32, paramTypes: *Oid, paramValues: **u8, paramLengths: *s32, paramFormats: *s32, resultFormat: s32) -> *PGresult #foreign libpq;
// extern PGresult *PQprepare(PGconn *conn, const char *stmtName,
// 						   const char *query, s32 nParams,
// 						   const Oid *paramTypes);
// extern PGresult *PQexecPrepared(PGconn *conn,
// 								const char *stmtName,
// 								s32 nParams,
// 								const char *const *paramValues,
// 								const s32 *paramLengths,
// 								const s32 *paramFormats,
// 								s32 resultFormat);

// /* Interface for multiple-result or asynchronous queries */
// extern s32	PQsendQuery(PGconn *conn, const char *query);
// extern s32	PQsendQueryParams(PGconn *conn,
// 							  const char *command,
// 							  s32 nParams,
// 							  const Oid *paramTypes,
// 							  const char *const *paramValues,
// 							  const s32 *paramLengths,
// 							  const s32 *paramFormats,
// 							  s32 resultFormat);
// extern s32	PQsendPrepare(PGconn *conn, const char *stmtName,
// 						  const char *query, s32 nParams,
// 						  const Oid *paramTypes);
// extern s32	PQsendQueryPrepared(PGconn *conn,
// 								const char *stmtName,
// 								s32 nParams,
// 								const char *const *paramValues,
// 								const s32 *paramLengths,
// 								const s32 *paramFormats,
// 								s32 resultFormat);
// extern s32	PQsetSingleRowMode(PGconn *conn);
// extern PGresult *PQgetResult(PGconn *conn);

// /* Routines for managing an asynchronous query */
// extern s32	PQisBusy(PGconn *conn);
// extern s32	PQconsumeInput(PGconn *conn);

// /* LISTEN/NOTIFY support */
// extern PGnotify *PQnotifies(PGconn *conn);

// /* Routines for copy in/out */
// extern s32	PQputCopyData(PGconn *conn, const char *buffer, s32 nbytes);
// extern s32	PQputCopyEnd(PGconn *conn, const char *errormsg);
// extern s32	PQgetCopyData(PGconn *conn, char **buffer, s32 async);

// /* Deprecated routines for copy in/out */
// extern s32	PQgetline(PGconn *conn, char *string, s32 length);
// extern s32	PQputline(PGconn *conn, const char *string);
// extern s32	PQgetlineAsync(PGconn *conn, char *buffer, s32 bufsize);
// extern s32	PQputnbytes(PGconn *conn, const char *buffer, s32 nbytes);
// extern s32	PQendcopy(PGconn *conn);

// /* Set blocking/nonblocking connection to the backend */
// extern s32	PQsetnonblocking(PGconn *conn, s32 arg);
// extern s32	PQisnonblocking(const PGconn *conn);
// extern s32	PQisthreadsafe(void);
// extern PGPing PQping(const char *conninfo);
// extern PGPing PQpingParams(const char *const *keywords,
// 						   const char *const *values, s32 expand_dbname);

// /* Force the write buffer to be written (or at least try) */
// extern s32	PQflush(PGconn *conn);

// /*
//  * "Fast path" interface --- not really recommended for application
//  * use
//  */
// extern PGresult *PQfn(PGconn *conn,
// 					  s32 fnid,
// 					  s32 *result_buf,
// 					  s32 *result_len,
// 					  s32 result_is_int,
// 					  const PQArgBlock *args,
// 					  s32 nargs);

// /* Accessor functions for PGresult objects */
PQresultStatus :: (res: *PGresult) -> ExecStatusType #foreign libpq;
// extern char *PQresStatus(ExecStatusType status);
PQresultErrorMessage :: (res: *PGresult) -> *u8 #foreign libpq;
// extern char *PQresultVerboseErrorMessage(const PGresult *res,
// 										 PGVerbosity verbosity,
// 										 PGContextVisibility show_context);
// extern char *PQresultErrorField(const PGresult *res, s32 fieldcode);
PQntuples :: (res: *PGresult) -> s32 #foreign libpq;
PQnfields :: (res: *PGresult) -> s32 #foreign libpq;
// extern s32	PQbinaryTuples(const PGresult *res);
PQfname :: (res: *PGresult, field_num: s32) -> *u8 #foreign libpq;
// extern s32	PQfnumber(const PGresult *res, const char *field_name);
// extern Oid	PQftable(const PGresult *res, s32 field_num);
// extern s32	PQftablecol(const PGresult *res, s32 field_num);
PQfformat :: (res: *PGresult, field_num: s32) -> s32 #foreign libpq;
PQftype :: (res: *PGresult, field_num: s32) -> Oid #foreign libpq;
// extern s32	PQfsize(const PGresult *res, s32 field_num);
PQfmod :: (res: *PGresult, field_num: s32) -> s32 #foreign libpq;
// extern char *PQcmdStatus(PGresult *res);
// extern char *PQoidStatus(const PGresult *res);	/* old and ugly */
// extern Oid	PQoidValue(const PGresult *res);	/* new and improved */
// extern char *PQcmdTuples(PGresult *res);
PQgetvalue :: (res: *PGresult, tup_num: s32, field_num: s32) -> *u8 #foreign libpq;
PQgetlength :: (res: *PGresult, tup_num: s32, field_num: s32) -> s32 #foreign libpq;
PQgetisnull :: (res: *PGresult, tup_num: s32, field_num: s32) -> s32 #foreign libpq;
// extern s32	PQnparams(const PGresult *res);
// extern Oid	PQparamtype(const PGresult *res, s32 param_num);

// /* Describe prepared statements and portals */
// extern PGresult *PQdescribePrepared(PGconn *conn, const char *stmt);
// extern PGresult *PQdescribePortal(PGconn *conn, const char *portal);
// extern s32	PQsendDescribePrepared(PGconn *conn, const char *stmt);
// extern s32	PQsendDescribePortal(PGconn *conn, const char *portal);

// /* Delete a PGresult */
PQclear :: (res: *PGresult) -> void #foreign libpq;

// /* For freeing other alloc'd results, such as PGnotify structs */
// extern void PQfreemem(void *ptr);

// /* Error when no password was given. */
// /* Note: depending on this is deprecated; use PQconnectionNeedsPassword(). */
// #define PQnoPasswordSupplied	"fe_sendauth: no password supplied\n"

// /* Create and manipulate PGresults */
// extern PGresult *PQmakeEmptyPGresult(PGconn *conn, ExecStatusType status);
// extern PGresult *PQcopyResult(const PGresult *src, s32 flags);
// extern s32	PQsetResultAttrs(PGresult *res, s32 numAttributes, PGresAttDesc *attDescs);
// extern void *PQresultAlloc(PGresult *res, size_t nBytes);
// extern size_t PQresultMemorySize(const PGresult *res);
// extern s32	PQsetvalue(PGresult *res, s32 tup_num, s32 field_num, char *value, s32 len);

// /* Quoting strings before inclusion in queries. */
// extern size_t PQescapeStringConn(PGconn *conn,
// 								 char *to, const char *from, size_t length,
// 								 s32 *error);
// extern char *PQescapeLiteral(PGconn *conn, const char *str, size_t len);
// extern char *PQescapeIdentifier(PGconn *conn, const char *str, size_t len);
// extern unsigned char *PQescapeByteaConn(PGconn *conn,
// 										const unsigned char *from, size_t from_length,
// 										size_t *to_length);
// extern unsigned char *PQunescapeBytea(const unsigned char *strtext,
// 									  size_t *retbuflen);

// /* These forms are deprecated! */
// extern size_t PQescapeString(char *to, const char *from, size_t length);
// extern unsigned char *PQescapeBytea(const unsigned char *from, size_t from_length,
// 									size_t *to_length);



// /* === in fe-print.c === */

// extern void PQprint(FILE *fout, /* output stream */
// 					const PGresult *res,
// 					const PQprintOpt *ps);	/* option structure */

// /*
//  * really old printing routines
//  */
// extern void PQdisplayTuples(const PGresult *res,
// 							FILE *fp,	/* where to send the output */
// 							s32 fillAlign,	/* pad the fields with spaces */
// 							const char *fieldSep,	/* field separator */
// 							s32 printHeader,	/* display headers? */
// 							s32 quiet);

// extern void PQprintTuples(const PGresult *res,
// 						  FILE *fout,	/* output stream */
// 						  s32 PrintAttNames,	/* print attribute names */
// 						  s32 TerseOutput,	/* delimiter bars */
// 						  s32 colWidth);	/* width of column, if 0, use
// 											 * variable width */


// /* === in fe-lobj.c === */

// /* Large-object access routines */
// extern s32	lo_open(PGconn *conn, Oid lobjId, s32 mode);
// extern s32	lo_close(PGconn *conn, s32 fd);
// extern s32	lo_read(PGconn *conn, s32 fd, char *buf, size_t len);
// extern s32	lo_write(PGconn *conn, s32 fd, const char *buf, size_t len);
// extern s32	lo_lseek(PGconn *conn, s32 fd, s32 offset, s32 whence);
// extern pg_int64 lo_lseek64(PGconn *conn, s32 fd, pg_int64 offset, s32 whence);
// extern Oid	lo_creat(PGconn *conn, s32 mode);
// extern Oid	lo_create(PGconn *conn, Oid lobjId);
// extern s32	lo_tell(PGconn *conn, s32 fd);
// extern pg_int64 lo_tell64(PGconn *conn, s32 fd);
// extern s32	lo_truncate(PGconn *conn, s32 fd, size_t len);
// extern s32	lo_truncate64(PGconn *conn, s32 fd, pg_int64 len);
// extern s32	lo_unlink(PGconn *conn, Oid lobjId);
// extern Oid	lo_import(PGconn *conn, const char *filename);
// extern Oid	lo_import_with_oid(PGconn *conn, const char *filename, Oid lobjId);
// extern s32	lo_export(PGconn *conn, Oid lobjId, const char *filename);

// /* === in fe-misc.c === */

// /* Get the version of the libpq library in use */
// extern s32	PQlibVersion(void);

// /* Determine length of multibyte encoded char at *s */
// extern s32	PQmblen(const char *s, s32 encoding);

// /* Determine display length of multibyte encoded char at *s */
// extern s32	PQdsplen(const char *s, s32 encoding);

// /* Get encoding id from environment variable PGCLIENTENCODING */
// extern s32	PQenv2encoding(void);

// /* === in fe-auth.c === */

// extern char *PQencryptPassword(const char *passwd, const char *user);
// extern char *PQencryptPasswordConn(PGconn *conn, const char *passwd, const char *user, const char *algorithm);

// /* === in encnames.c === */

// extern s32	pg_char_to_encoding(const char *name);
// extern const char *pg_encoding_to_char(s32 encoding);
// extern s32	pg_valid_server_encoding_id(s32 encoding);

// /* == in fe-secure-openssl.c === */

// /* Support for overriding sslpassword handling with a callback. */
// typedef s32 (*PQsslKeyPassHook_type)(char *buf, s32 size, PGconn *conn);
// extern PQsslKeyPassHook_type PQgetSSLKeyPassHook(void);
// extern void PQsetSSLKeyPassHook(PQsslKeyPassHook_type hook);
// extern s32 PQdefaultSSLKeyPassHook(char *buf, s32 size, PGconn *conn);

#scope_file

libpq :: #foreign_system_library "libpq";
