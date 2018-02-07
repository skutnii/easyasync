#  Promise Specification

This is the specification for promises defined in lib/Promise.swift. It is closely based on [Promises/A+ specification](https://promisesaplus.com/) but differs from it in several important points as promises defined here are type safe.

## 1. Terminology

1.1     “promise” is an instance of `Promise<T>` generic class defined in lib/Promise.swift.
1.2     “thenable” is an object confirming to `Thenable` protocol defined in lib/Promise.swift.
1.3     “value” is any legal Swift value (including nil, a thenable, or a promise).
1.4     “error” is any Swift `Error` instance, including custom errors.
1.5     “reason” is a value that indicates why a promise was rejected.

## 2. Requirements

### 2.1 Promise states

2.1.1 When pending, a promise:
    2.1.1.1 may transition to either the fulfilled or rejected state.
    
2.1.2 When fulfilled, a promise:
    2.1.2.1 must not transition to any other state.
    2.1.2.2 must have a value, which must not change.
    
2.1.3 When rejected, a promise:
    2.1.3.1 must not transition to any other state.
    2.1.3.2 must have a reason, which must not change.
    
Here, “must not change” means immutable identity (i.e. ===), but does not imply deep immutability.

## 3. `Thenable`

`Thenable` protocol defines an object to which callbacks may be attached. The minimal interface for such a protocol must define at least

[3_1]:3.1 Associated value type , e.g. `associatedtype Value`.

3.2 A generic `then` method. Let `V` is the associated value type [3.1][3_1]. Then the signature of the method must be

    func then<O, E>(_ onSuccess: ((V) throws -> O)?, _ onFailure: ((E) throws -> O)?)
    



