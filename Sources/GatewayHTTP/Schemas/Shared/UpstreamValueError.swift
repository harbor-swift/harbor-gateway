/// An upstream answer the HTTP contract can't hold, such as an unspecified enum or a missing date.
///
/// It isn't an HTTP error, so `ErrorMiddleware` logs it and answers `500` rather than inventing a value.
struct UpstreamValueError: Error {
    let field: String
}
