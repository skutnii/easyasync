#  Promise Specification

This is the specification for promises defined in lib/Promise.swift. It is closely based on [Promises/A+ specification](https://promisesaplus.com/) but differs from it in several important points as promises defined here are type safe.

## 1 Terminology

+ 1.1 “promise” is an instance of `Promise<T>` generic class defined in lib/Promise.swift.
+ 1.2 “value” is any legal Swift value (including nil, a thenable, or a promise).
+ 1.3 “error” is any Swift `Error` instance, including custom errors.
+ 1.4 “reason” is a value that indicates why a promise was rejected.

## 2 Requirements

### 2.1 Promise states

+ 2.1.1 When pending, a promise:
    + 2.1.1.1 may transition to either the fulfilled or rejected state.
+ 2.1.2 When fulfilled, a promise:
    + 2.1.2.1 must not transition to any other state.
    + 2.1.2.2 must have a value, which must not change.
+ 2.1.3 When rejected, a promise:
    + 2.1.3.1 must not transition to any other state.
    + 2.1.3.2 must have a reason, which must not change.
    
Here, “must not change” means immutable identity (i.e. ===), but does not imply deep immutability.

### 2.2 Promise chaining

Two promises of the same type may be chained after each other.
Let `promise1, promise2: Promise<T>`. Then, if `promise2` is chained after `promise1`,
+ 2.2.1 after `promise1` is fulfilled with the value `x`, `promise2` is also fulfilled with the same value;
+ 2.2.2 after `promise1` is rejected with some reason, `promise2` is also rejected with the same reason.

### 2.3 Rescue conditions
+ 2.3.1 A valid rescue handler is a closure receiving a single argument of any type
+ 2.3.2 A value `x` is said to meet the rescue condition for a valid rescue handler `R`, if
    ```Swift
    (x is R) == true
    ```

## 3 `Promise<T>`

### 3.1 `then` methods

#### 3.1.1 Untyped `then`
```Swift
func then(_ onSuccess: ((T) throws -> ())?, _ onFailure: ((Any?) -> ())?)
```
    
+ 3.1.1.1 If `onSuccess` is `nil`, it is ignored.
+ 3.1.1.2 If `onSuccess` is not nil, it must be called after the callee promise is fulfilled with the value of the promise.
+ 3.1.1.3 If callee is already fulfilled with a value `x`, and `onSuccess` is not nil, `onSuccess` is called immediately with `x` as an argument.
+ 3.1.1.4 If callee is already rejected with a reason `r`, and `onError` is not nil, `onError` is called immediately with `r` as an argument.
+ 3.1.1.5 If `onSuccess` throws an error when called with the promise's value [3.1.1.2],
    + 3.1.1.5.1 if `onFailure` is not nil, `onFailure` is called with the error as its argument;
    + 3.1.1.5.2 if `onFailure` is nil, the error is ignored.
        
#### 3.1.2 Typed `then`
```Swift
func then<O>(_ onSuccess: @escaping (T) throws -> O) -> Promise<O>
```
Let `promise1: Promise<T>`, `O` be some type, `success: (T) throws -> O` and
```Swift
promise2 = promise1.then(success)
```
+ 3.1.2.1 After `promise1` is fulfilled with a value `x`, `success` must be called with `x` as an argument.
+ 3.1.2.2 If callee is already fulfilled with a value `x` `success` is called immediately with `x` as an argument.
+ 3.1.2.3 If `success` returns a value `x`, `promise2` must be fulfilled with `x`.
+ 3.1.2.4 If an error is thrown in `success`, `promise2` must be rejected with the error as reason.
+ 3.1.2.5 If `promise1` is rejected, `promise2` must be rejected with the same reason.

#### 3.1.3 Typed asynchronous `then`
```Swift
func then<O>(async onSuccess: @escaping (T) throws -> Promise<O>) -> Promise<O>
```
Let `promise1: Promise<T>`, `O` be some type, `success: (T) throws -> Promise<O>` and
```Swift
promise2 = promise1.then(success)
```
+ 3.1.3.1 After `promise1` is fulfilled with a value `x`, `success` must be called with `x` as an argument.
+ 3.1.3.2 If callee is already fulfilled with a value `x` `success` is called immediately with `x` as an argument.
+ 3.1.3.3 If `success` returns `x: Promise<O>`, `promise2` must be chained after `x` [2.2].
+ 3.1.2.4 If an error is thrown in `success`, `promise2` must be rejected with the error as reason.
+ 3.1.2.5 If `promise1` is rejected, `promise2` must be rejected with the same reason.
    
### 3.2 `rescue` methods

#### 3.2.1 Void `rescue`
```Swift
func rescue<E>(_ onError: @escaping (E) -> ())
```
+ 3.2.1.1 After callee is rejected with reason `r`,
    + 3.2.1.1.1 if `r` meets the rescue condition [2.3] for `onError`, `onError` must be called with `r` as an argument;
    + 3.2.1.1.2 if `r` does not meet the rescue condition for `onError`, `onError` is not called.
+ 3.2.1.2 If callee is already rejected with reason `r` and `r`meets the rescue condition for `onError`, `onError` is called immediately with `r` as an argument.

#### 3.2.2 Non-void `rescue`
```Swift
func rescue<E, O>(_ onError: @escaping (E) throws -> O) -> Promise<O>
```
Let `promise1: Promise<T>`, `E,O` be some types, `handler: (T) throws -> O` and
```Swift
promise2 = promise1.rescue(handler)
```
+ 3.2.2.1 After `promise1` is rejected with reason `r`, and `r` meets the rescue condition [2.3] for `onError`, `onError` must be called with `r` as an argument.
+ 3.2.2.2 If `promise1` is already rejected with reason `r`, and `r`meets the rescue condition [2.3] for `onError`, `onError` must be called immediately with `r` as an argument.
+ 3.2.2.3 If `onError` was called and returned a value `x`, `promise2` must be resolved with `x` as value.
+ 3.2.2.4 If `onError` was called and threw an error, `promise2` must be rejected with the error as reason.
+ 3.2.2.5 if `promise1` was rejected with a reason `r`, but `r` does not meet the rescue condition for `onError`, `onError` must not be called, and `promise2` must be rejected with `r` as reason (this way an error will travel down the promise chain until it meets a matching rescue handler).

#### 3.2.3 Non-void asynchronous `rescue`
```Swift
func rescue<E, O>(_ onError: @escaping (E) throws -> Promise<O>) -> Promise<O>
```
Let `promise1: Promise<T>`, `E,O` be some types, `handler: (T) throws -> Promise<O>` and
```Swift
promise2 = promise1.rescue(handler)
```
+ 3.2.3.1 After `promise1` is rejected with reason `r`, and `r` meets the rescue condition [2.3] for `onError`, `onError` must be called with `r` as an argument.
+ 3.2.3.2 If `promise1` is already rejected with reason `r`, and `r`meets the rescue condition [2.3] for `onError`, `onError` must be called immediately with `r` as an argument.
+ 3.2.3.3 If `onError` was called and returned a promise `x`, `promise2` must be chained after `x` [2.2].
+ 3.2.3.4 If `onError` was called and threw an error, `promise2` must be rejected with the error as reason.
+ 3.2.3.5 if `promise1` was rejected with a reason `r`, but `r` does not meet the rescue condition for `onError`, `onError` must not be called, and `promise2` must be rejected with `r` as reason.


