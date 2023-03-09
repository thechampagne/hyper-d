/*
 * Copyright 2023 XXIV
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import core.stdc.config;

extern (C):

/*
 Return in iter functions to continue iterating.
 */
enum HYPER_ITER_CONTINUE = 0;

/*
 Return in iter functions to stop iterating.
 */
enum HYPER_ITER_BREAK = 1;

/*
 An HTTP Version that is unspecified.
 */
enum HYPER_HTTP_VERSION_NONE = 0;

/*
 The HTTP/1.0 version.
 */
enum HYPER_HTTP_VERSION_1_0 = 10;

/*
 The HTTP/1.1 version.
 */
enum HYPER_HTTP_VERSION_1_1 = 11;

/*
 The HTTP/2 version.
 */
enum HYPER_HTTP_VERSION_2 = 20;

/*
 Sentinel value to return from a read or write callback that the operation
 is pending.
 */
enum HYPER_IO_PENDING = 4294967295;

/*
 Sentinel value to return from a read or write callback that the operation
 has errored.
 */
enum HYPER_IO_ERROR = 4294967294;

/*
 Return in a poll function to indicate it was ready.
 */
enum HYPER_POLL_READY = 0;

/*
 Return in a poll function to indicate it is still pending.

 The passed in `hyper_waker` should be registered to wake up the task at
 some later point.
 */
enum HYPER_POLL_PENDING = 1;

/*
 Return in a poll function indicate an error.
 */
enum HYPER_POLL_ERROR = 3;

/*
 A return code for many of hyper's methods.
 */
enum hyper_code
{
    /*
     All is well.
     */
    HYPERE_OK = 0,
    /*
     General error, details in the `hyper_error *`.
     */
    HYPERE_ERROR = 1,
    /*
     A function argument was invalid.
     */
    HYPERE_INVALID_ARG = 2,
    /*
     The IO transport returned an EOF when one wasn't expected.

     This typically means an HTTP request or response was expected, but the
     connection closed cleanly without sending (all of) it.
     */
    HYPERE_UNEXPECTED_EOF = 3,
    /*
     Aborted by a user supplied callback.
     */
    HYPERE_ABORTED_BY_CALLBACK = 4,
    /*
     An optional hyper feature was not enabled.
     */
    HYPERE_FEATURE_NOT_ENABLED = 5,
    /*
     The peer sent an HTTP message that could not be parsed.
     */
    HYPERE_INVALID_PEER_MESSAGE = 6
}

/*
 A descriptor for what type a `hyper_task` value is.
 */
enum hyper_task_return_type
{
    /*
     The value of this task is null (does not imply an error).
     */
    HYPER_TASK_EMPTY = 0,
    /*
     The value of this task is `hyper_error *`.
     */
    HYPER_TASK_ERROR = 1,
    /*
     The value of this task is `hyper_clientconn *`.
     */
    HYPER_TASK_CLIENTCONN = 2,
    /*
     The value of this task is `hyper_response *`.
     */
    HYPER_TASK_RESPONSE = 3,
    /*
     The value of this task is `hyper_buf *`.
     */
    HYPER_TASK_BUF = 4
}

/*
 A streaming HTTP body.
 */
struct hyper_body;

/*
 A buffer of bytes that is sent or received on a `hyper_body`.
 */
struct hyper_buf;

/*
 An HTTP client connection handle.

 These are used to send a request on a single connection. It's possible to
 send multiple requests on a single connection, such as when HTTP/1
 keep-alive or HTTP/2 is used.
 */
struct hyper_clientconn;

/*
 An options builder to configure an HTTP client connection.
 */
struct hyper_clientconn_options;

/*
 An async context for a task that contains the related waker.
 */
struct hyper_context;

/*
 A more detailed error object returned by some hyper functions.
 */
struct hyper_error;

/*
 A task executor for `hyper_task`s.
 */
struct hyper_executor;

/*
 An HTTP header map.

 These can be part of a request or response.
 */
struct hyper_headers;

/*
 An IO object used to represent a socket or similar concept.
 */
struct hyper_io;

/*
 An HTTP request.
 */
struct hyper_request;

/*
 An HTTP response.
 */
struct hyper_response;

/*
 An async task.
 */
struct hyper_task;

/*
 A waker that is saved and used to waken a pending task.
 */
struct hyper_waker;

alias hyper_body_foreach_callback = int function (void*, const(hyper_buf)*);

alias hyper_body_data_callback = int function (void*, hyper_context*, hyper_buf**);

alias hyper_request_on_informational_callback = void function (void*, hyper_response*);

alias hyper_headers_foreach_callback = int function (void*, const(ubyte)*, size_t, const(ubyte)*, size_t);

alias hyper_io_read_callback = c_ulong function (void*, hyper_context*, ubyte*, size_t);

alias hyper_io_write_callback = c_ulong function (void*, hyper_context*, const(ubyte)*, size_t);

/*
 Returns a static ASCII (null terminated) string of the hyper version.
 */
const(char)* hyper_version ();

/*
 Create a new "empty" body.

 If not configured, this body acts as an empty payload.
 */
hyper_body* hyper_body_new ();

/*
 Free a `hyper_body *`.
 */
void hyper_body_free (hyper_body* body_);

/*
 Return a task that will poll the body for the next buffer of data.

 The task value may have different types depending on the outcome:

 - `HYPER_TASK_BUF`: Success, and more data was received.
 - `HYPER_TASK_ERROR`: An error retrieving the data.
 - `HYPER_TASK_EMPTY`: The body has finished streaming data.

 This does not consume the `hyper_body *`, so it may be used to again.
 However, it MUST NOT be used or freed until the related task completes.
 */
hyper_task* hyper_body_data (hyper_body* body_);

/*
 Return a task that will poll the body and execute the callback with each
 body chunk that is received.

 The `hyper_buf` pointer is only a borrowed reference, it cannot live outside
 the execution of the callback. You must make a copy to retain it.

 The callback should return `HYPER_ITER_CONTINUE` to continue iterating
 chunks as they are received, or `HYPER_ITER_BREAK` to cancel.

 This will consume the `hyper_body *`, you shouldn't use it anymore or free it.
 */
hyper_task* hyper_body_foreach (
    hyper_body* body_,
    hyper_body_foreach_callback func,
    void* userdata);

/*
 Set userdata on this body, which will be passed to callback functions.
 */
void hyper_body_set_userdata (hyper_body* body_, void* userdata);

/*
 Set the data callback for this body.

 The callback is called each time hyper needs to send more data for the
 body. It is passed the value from `hyper_body_set_userdata`.

 If there is data available, the `hyper_buf **` argument should be set
 to a `hyper_buf *` containing the data, and `HYPER_POLL_READY` should
 be returned.

 Returning `HYPER_POLL_READY` while the `hyper_buf **` argument points
 to `NULL` will indicate the body has completed all data.

 If there is more data to send, but it isn't yet available, a
 `hyper_waker` should be saved from the `hyper_context *` argument, and
 `HYPER_POLL_PENDING` should be returned. You must wake the saved waker
 to signal the task when data is available.

 If some error has occurred, you can return `HYPER_POLL_ERROR` to abort
 the body.
 */
void hyper_body_set_data_func (hyper_body* body_, hyper_body_data_callback func);

/*
 Create a new `hyper_buf *` by copying the provided bytes.

 This makes an owned copy of the bytes, so the `buf` argument can be
 freed or changed afterwards.

 This returns `NULL` if allocating a new buffer fails.
 */
hyper_buf* hyper_buf_copy (const(ubyte)* buf, size_t len);

/*
 Get a pointer to the bytes in this buffer.

 This should be used in conjunction with `hyper_buf_len` to get the length
 of the bytes data.

 This pointer is borrowed data, and not valid once the `hyper_buf` is
 consumed/freed.
 */
const(ubyte)* hyper_buf_bytes (const(hyper_buf)* buf);

/*
 Get the length of the bytes this buffer contains.
 */
size_t hyper_buf_len (const(hyper_buf)* buf);

/*
 Free this buffer.
 */
void hyper_buf_free (hyper_buf* buf);

/*
 Starts an HTTP client connection handshake using the provided IO transport
 and options.

 Both the `io` and the `options` are consumed in this function call.

 The returned `hyper_task *` must be polled with an executor until the
 handshake completes, at which point the value can be taken.
 */
hyper_task* hyper_clientconn_handshake (
    hyper_io* io,
    hyper_clientconn_options* options);

/*
 Send a request on the client connection.

 Returns a task that needs to be polled until it is ready. When ready, the
 task yields a `hyper_response *`.
 */
hyper_task* hyper_clientconn_send (hyper_clientconn* conn, hyper_request* req);

/*
 Free a `hyper_clientconn *`.
 */
void hyper_clientconn_free (hyper_clientconn* conn);

/*
 Creates a new set of HTTP clientconn options to be used in a handshake.
 */
hyper_clientconn_options* hyper_clientconn_options_new ();

/*
 Set the whether or not header case is preserved.

 Pass `0` to allow lowercase normalization (default), `1` to retain original case.
 */
void hyper_clientconn_options_set_preserve_header_case (
    hyper_clientconn_options* opts,
    int enabled);

/*
 Set the whether or not header order is preserved.

 Pass `0` to allow reordering (default), `1` to retain original ordering.
 */
void hyper_clientconn_options_set_preserve_header_order (
    hyper_clientconn_options* opts,
    int enabled);

/*
 Free a `hyper_clientconn_options *`.
 */
void hyper_clientconn_options_free (hyper_clientconn_options* opts);

/*
 Set the client background task executor.

 This does not consume the `options` or the `exec`.
 */
void hyper_clientconn_options_exec (
    hyper_clientconn_options* opts,
    const(hyper_executor)* exec);

/*
 Set the whether to use HTTP2.

 Pass `0` to disable, `1` to enable.
 */
hyper_code hyper_clientconn_options_http2 (hyper_clientconn_options* opts, int enabled);

/*
 Set the whether to include a copy of the raw headers in responses
 received on this connection.

 Pass `0` to disable, `1` to enable.

 If enabled, see `hyper_response_headers_raw()` for usage.
 */
hyper_code hyper_clientconn_options_headers_raw (
    hyper_clientconn_options* opts,
    int enabled);

/*
 Frees a `hyper_error`.
 */
void hyper_error_free (hyper_error* err);

/*
 Get an equivalent `hyper_code` from this error.
 */
hyper_code hyper_error_code (const(hyper_error)* err);

/*
 Print the details of this error to a buffer.

 The `dst_len` value must be the maximum length that the buffer can
 store.

 The return value is number of bytes that were written to `dst`.
 */
size_t hyper_error_print (const(hyper_error)* err, ubyte* dst, size_t dst_len);

/*
 Construct a new HTTP request.
 */
hyper_request* hyper_request_new ();

/*
 Free an HTTP request if not going to send it on a client.
 */
void hyper_request_free (hyper_request* req);

/*
 Set the HTTP Method of the request.
 */
hyper_code hyper_request_set_method (
    hyper_request* req,
    const(ubyte)* method,
    size_t method_len);

/*
 Set the URI of the request.

 The request's URI is best described as the `request-target` from the RFCs. So in HTTP/1,
 whatever is set will get sent as-is in the first line (GET $uri HTTP/1.1). It
 supports the 4 defined variants, origin-form, absolute-form, authority-form, and
 asterisk-form.

 The underlying type was built to efficiently support HTTP/2 where the request-target is
 split over :scheme, :authority, and :path. As such, each part can be set explicitly, or the
 type can parse a single contiguous string and if a scheme is found, that slot is "set". If
 the string just starts with a path, only the path portion is set. All pseudo headers that
 have been parsed/set are sent when the connection type is HTTP/2.

 To set each slot explicitly, use `hyper_request_set_uri_parts`.
 */
hyper_code hyper_request_set_uri (
    hyper_request* req,
    const(ubyte)* uri,
    size_t uri_len);

/*
 Set the URI of the request with separate scheme, authority, and
 path/query strings.

 Each of `scheme`, `authority`, and `path_and_query` should either be
 null, to skip providing a component, or point to a UTF-8 encoded
 string. If any string pointer argument is non-null, its corresponding
 `len` parameter must be set to the string's length.
 */
hyper_code hyper_request_set_uri_parts (
    hyper_request* req,
    const(ubyte)* scheme,
    size_t scheme_len,
    const(ubyte)* authority,
    size_t authority_len,
    const(ubyte)* path_and_query,
    size_t path_and_query_len);

/*
 Set the preferred HTTP version of the request.

 The version value should be one of the `HYPER_HTTP_VERSION_` constants.

 Note that this won't change the major HTTP version of the connection,
 since that is determined at the handshake step.
 */
hyper_code hyper_request_set_version (hyper_request* req, int version_);

/*
 Gets a reference to the HTTP headers of this request

 This is not an owned reference, so it should not be accessed after the
 `hyper_request` has been consumed.
 */
hyper_headers* hyper_request_headers (hyper_request* req);

/*
 Set the body of the request.

 The default is an empty body.

 This takes ownership of the `hyper_body *`, you must not use it or
 free it after setting it on the request.
 */
hyper_code hyper_request_set_body (hyper_request* req, hyper_body* body_);

/*
 Set an informational (1xx) response callback.

 The callback is called each time hyper receives an informational (1xx)
 response for this request.

 The third argument is an opaque user data pointer, which is passed to
 the callback each time.

 The callback is passed the `void *` data pointer, and a
 `hyper_response *` which can be inspected as any other response. The
 body of the response will always be empty.

 NOTE: The `hyper_response *` is just borrowed data, and will not
 be valid after the callback finishes. You must copy any data you wish
 to persist.
 */
hyper_code hyper_request_on_informational (
    hyper_request* req,
    hyper_request_on_informational_callback callback,
    void* data);

/*
 Free an HTTP response after using it.
 */
void hyper_response_free (hyper_response* resp);

/*
 Get the HTTP-Status code of this response.

 It will always be within the range of 100-599.
 */
ushort hyper_response_status (const(hyper_response)* resp);

/*
 Get a pointer to the reason-phrase of this response.

 This buffer is not null-terminated.

 This buffer is owned by the response, and should not be used after
 the response has been freed.

 Use `hyper_response_reason_phrase_len()` to get the length of this
 buffer.
 */
const(ubyte)* hyper_response_reason_phrase (const(hyper_response)* resp);

/*
 Get the length of the reason-phrase of this response.

 Use `hyper_response_reason_phrase()` to get the buffer pointer.
 */
size_t hyper_response_reason_phrase_len (const(hyper_response)* resp);

/*
 Get a reference to the full raw headers of this response.

 You must have enabled `hyper_clientconn_options_headers_raw()`, or this
 will return NULL.

 The returned `hyper_buf *` is just a reference, owned by the response.
 You need to make a copy if you wish to use it after freeing the
 response.

 The buffer is not null-terminated, see the `hyper_buf` functions for
 getting the bytes and length.
 */
const(hyper_buf)* hyper_response_headers_raw (const(hyper_response)* resp);

/*
 Get the HTTP version used by this response.

 The returned value could be:

 - `HYPER_HTTP_VERSION_1_0`
 - `HYPER_HTTP_VERSION_1_1`
 - `HYPER_HTTP_VERSION_2`
 - `HYPER_HTTP_VERSION_NONE` if newer (or older).
 */
int hyper_response_version (const(hyper_response)* resp);

/*
 Gets a reference to the HTTP headers of this response.

 This is not an owned reference, so it should not be accessed after the
 `hyper_response` has been freed.
 */
hyper_headers* hyper_response_headers (hyper_response* resp);

/*
 Take ownership of the body of this response.

 It is safe to free the response even after taking ownership of its body.
 */
hyper_body* hyper_response_body (hyper_response* resp);

/*
 Iterates the headers passing each name and value pair to the callback.

 The `userdata` pointer is also passed to the callback.

 The callback should return `HYPER_ITER_CONTINUE` to keep iterating, or
 `HYPER_ITER_BREAK` to stop.
 */
void hyper_headers_foreach (
    const(hyper_headers)* headers,
    hyper_headers_foreach_callback func,
    void* userdata);

/*
 Sets the header with the provided name to the provided value.

 This overwrites any previous value set for the header.
 */
hyper_code hyper_headers_set (
    hyper_headers* headers,
    const(ubyte)* name,
    size_t name_len,
    const(ubyte)* value,
    size_t value_len);

/*
 Adds the provided value to the list of the provided name.

 If there were already existing values for the name, this will append the
 new value to the internal list.
 */
hyper_code hyper_headers_add (
    hyper_headers* headers,
    const(ubyte)* name,
    size_t name_len,
    const(ubyte)* value,
    size_t value_len);

/*
 Create a new IO type used to represent a transport.

 The read and write functions of this transport should be set with
 `hyper_io_set_read` and `hyper_io_set_write`.
 */
hyper_io* hyper_io_new ();

/*
 Free an unused `hyper_io *`.

 This is typically only useful if you aren't going to pass ownership
 of the IO handle to hyper, such as with `hyper_clientconn_handshake()`.
 */
void hyper_io_free (hyper_io* io);

/*
 Set the user data pointer for this IO to some value.

 This value is passed as an argument to the read and write callbacks.
 */
void hyper_io_set_userdata (hyper_io* io, void* data);

/*
 Set the read function for this IO transport.

 Data that is read from the transport should be put in the `buf` pointer,
 up to `buf_len` bytes. The number of bytes read should be the return value.

 It is undefined behavior to try to access the bytes in the `buf` pointer,
 unless you have already written them yourself. It is also undefined behavior
 to return that more bytes have been written than actually set on the `buf`.

 If there is no data currently available, a waker should be claimed from
 the `ctx` and registered with whatever polling mechanism is used to signal
 when data is available later on. The return value should be
 `HYPER_IO_PENDING`.

 If there is an irrecoverable error reading data, then `HYPER_IO_ERROR`
 should be the return value.
 */
void hyper_io_set_read (hyper_io* io, hyper_io_read_callback func);

/*
 Set the write function for this IO transport.

 Data from the `buf` pointer should be written to the transport, up to
 `buf_len` bytes. The number of bytes written should be the return value.

 If no data can currently be written, the `waker` should be cloned and
 registered with whatever polling mechanism is used to signal when data
 is available later on. The return value should be `HYPER_IO_PENDING`.

 Yeet.

 If there is an irrecoverable error reading data, then `HYPER_IO_ERROR`
 should be the return value.
 */
void hyper_io_set_write (hyper_io* io, hyper_io_write_callback func);

/*
 Creates a new task executor.
 */
const(hyper_executor)* hyper_executor_new ();

/*
 Frees an executor and any incomplete tasks still part of it.
 */
void hyper_executor_free (const(hyper_executor)* exec);

/*
 Push a task onto the executor.

 The executor takes ownership of the task, it should not be accessed
 again unless returned back to the user with `hyper_executor_poll`.
 */
hyper_code hyper_executor_push (const(hyper_executor)* exec, hyper_task* task);

/*
 Polls the executor, trying to make progress on any tasks that have notified
 that they are ready again.

 If ready, returns a task from the executor that has completed.

 If there are no ready tasks, this returns `NULL`.
 */
hyper_task* hyper_executor_poll (const(hyper_executor)* exec);

/*
 Free a task.
 */
void hyper_task_free (hyper_task* task);

/*
 Takes the output value of this task.

 This must only be called once polling the task on an executor has finished
 this task.

 Use `hyper_task_type` to determine the type of the `void *` return value.
 */
void* hyper_task_value (hyper_task* task);

/*
 Query the return type of this task.
 */
hyper_task_return_type hyper_task_type (hyper_task* task);

/*
 Set a user data pointer to be associated with this task.

 This value will be passed to task callbacks, and can be checked later
 with `hyper_task_userdata`.
 */
void hyper_task_set_userdata (hyper_task* task, void* userdata);

/*
 Retrieve the userdata that has been set via `hyper_task_set_userdata`.
 */
void* hyper_task_userdata (hyper_task* task);

/*
 Copies a waker out of the task context.
 */
hyper_waker* hyper_context_waker (hyper_context* cx);

/*
 Free a waker that hasn't been woken.
 */
void hyper_waker_free (hyper_waker* waker);

/*
 Wake up the task associated with a waker.

 NOTE: This consumes the waker. You should not use or free the waker afterwards.
 */
void hyper_waker_wake (hyper_waker* waker);
