package apperror

import "fmt"

// AppError is a structured application error with an HTTP status code.
type AppError struct {
	Code    int
	Message string
	Err     error
}

func (e *AppError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %v", e.Message, e.Err)
	}
	return e.Message
}

func (e *AppError) Unwrap() error { return e.Err }

func New(code int, message string, err error) *AppError {
	return &AppError{Code: code, Message: message, Err: err}
}

func NotFound(resource string) *AppError {
	return New(404, resource+" not found", nil)
}

func Unauthorized(msg string) *AppError {
	return New(401, msg, nil)
}

func BadRequest(msg string) *AppError {
	return New(400, msg, nil)
}

func Internal(err error) *AppError {
	return New(500, "internal server error", err)
}
