#  Promise Specification

This is the specification for promises defined in lib/Promise.swift. It is closely based on [Promises/A+ specification](https://promisesaplus.com/) but differs from it in several important points as promises defined here are type safe.

## 1 Terminology

+ 1.1 “promise” is an instance of `Promise<T>` generic class defined in lib/Promise.swift.
+ 1.2 “thenable” is an object confirming to `Thenable` protocol defined in lib/Promise.swift.
+ 1.3 “value” is any legal Swift value (including nil, a thenable, or a promise).
+ 1.4 “error” is any Swift `Error` instance, including custom errors.
+ 1.5 “reason” is a value that indicates why a promise was rejected.

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

## 3 `Thenable`

`Thenable` protocol defines an object to which callbacks may be attached. The minimal interface for such a protocol must define at least

+ 3.1 Associated value type , e.g. `associatedtype Value`.
+ 3.2 A `then` method. Let `V` be the associated value type [3.1]. Then the signature of the method must be
  ```Swift
  func then(_ onSuccess: ((V) throws -> ())?, _ onFailure: ((Any?) -> ())?)
  ```

## 4 `Promise<T>`

### 4.1 States

A promise must be in one of three states: pending, fulfilled, or rejected.

+ 4.1.1 When pending, a promise:
    + 4.1.1.1 may transition to either the fulfilled or rejected state.
+ 4.1.2 When fulfilled, a promise:
    + 4.1.2.1 must not transition to any other state.
    + 4.1.2.2 must have a value, which must not change.
+ 4.1.3 When rejected, a promise:
    + 4.1.3.1 must not transition to any other state.
    + 4.1.3.2 must have a reason, which must not change.
    
Here, “must not change” means immutable identity (i.e. ===), but does not imply deep immutability.

### 4.2 `then` methods

+ 4.2.1 
    ```Swift 
    func then(_ onSuccess: ((T) throws -> ())?, _ onFailure: ((Any?) -> ())?)
    ```
    This is the untyped `then` required by `Thenable` protocol.
    + 4.2.1.1 If `onSuccess` is `nil`, it is ignored.
    + 4.2.1.2 If `onSuccess` is not nil, it must be called after the callee promise is fulfilled with the value of the promise.
    + 4.2.1.3 If `onSuccess` throws an error when called with the promise's value [4.2.1.2],
        + 4.2.1.3.1 if `onFailure` is not nil, `onFailure` is called with the error as its argument;
        + 4.2.1.3.2 if `onFailure` is nil, the error must be caught by the callee promise.
        
+ 4.2.2
    ```Swift
    func then<O>(_ onSuccess: @escaping (T) throws -> O) -> Promise<O>
    ```
    Let `promise1: Promise<T>`, `O` be some type, `success: (T) throws -> O` and 
    ```Swift
    promise2 = promise1.then(success)
    ```
    + 4.2.2.1 `success` must be called after `promise1` is fulfilled.
    + 4.2.2.2 If `success` returns a value, `promise2` must be fulfilled with the value.
    + 4.2.2.3 If an error is thrown in `success`, `promise2` must be rejected with the error as reason. 
    
