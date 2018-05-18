# easyasync

This is a library of some useful Swift code I wrote initially in the context of a test task for a job interview. In the process, i developed a couple of interesting solutions to common programming problems. The code works for both iOS and OS X.

Then I have extracted the things that I feel make life a lot easier into this package.

Current version is 0.2.1.

Features

See CHANGELOG.md

## Usage tips

This library is available as a CocoaPod named EasyAsync.

### Promise

#### In a nutshell

Promises are a solution to the callback pyramid of doom problem that arises when using an asynchronous API. Let us say, you have to take data by HTTP from three different sources. With `URLSession` you would write
```Swift
URLSession.shared.dataTask(with: request1) {
    data1, response1, error1 in
    let request2 = createSecondRequest(fromData: data1)
    URLSession.shared.dataTask(with: request2) {
        data2, response2, error2 in
        let request3 = createThirdRequest(fromData: data2)
        URLSession.shared.dataTask(with: request3) {
            data3, response3, error3 in
            processData(data1, data2, data3)
        } .resume()
    } .resume()
} .resume()
```
This code is not executing in the order it is written and if you add error handling to it, your life turns into a nightmare.

With promises, an equivalent code looks like this (we are using `Fetch.request(_:)` - a promise-based solution for HTTP communication):

```Swift
var firstData: Data? = nil
var secondData: Data? = nil

Fetch.request(request1).then(async: {
    data1 -> Promise<Data> in
    firstData = data1
    let request = createSecondRequest(fromData: data1)
    return Fetch.request(request)
}).then(async: {
    data2 -> Promise<Data> in
    secondData = data2
    let request = createSecondRequest(fromData: data2)
    return Fetch.request(request)
}).then({
    thirdData in
    processData(firstData!, secondData!, thirdData)
}).rescue({
    reason in
    handleError(reason)
})
```

This way the code is executed in the order it was written. With promises, asynchronous code looks a lot more like synchronous.


Note that error handling was added here. If an error is thrown somewhere in the process, then the error propagates down the promise chain until it meets a matching `rescue`. So a single `rescue` at the end of the example catches all the errors - this would be nearly impossible in the pyramid of doom.

See also [JavaScript promises documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises).

#### Making promises

In the example above, two variables were defined to hold intermediate operations results. While this solution is probably the most concise, it may be not the best in terms of encapsulation. Using Swift tuples, it is possible to write a solution that would eliminate the need for extra variables.

```Swift
func fetchSecondData(for data1: Data) -> Promise<(Data, Data)> {
    let request = createSecondRequest(fromData: data1)
    let promise = Promise<(Data, Data)>()
    Fetch.request(request).then {
        data2 in
        promise.resolve((data1, data2))
    } .rescue {
        (reason: Any?) in
        promise.reject(reason)
    }
    
    return promise
}

func fetchThirdData(for dataTuple: (Data, Data)) -> Promise<(Data, Data, Data)> {
    let (data1, data2) = dataTuple
    let request = createThirdRequest(fromData: data2)
    let promise = Promise<(Data, Data, Data)>()
    Fetch.request(request).then {
        data3 in
        promise.resolve((data1, data2, data3))
    } .rescue {
        (reason: Any?) in
        promise.reject(reason)
    }
    
    return promise
}

Fetch.request(request1).then(async: {
    data1 -> Promise<(Data, Data)> in
    return fetchSecondData(for: data1)
}).then(async: {
    (dataTuple) -> Promise<(Data, Data, Data)> in
    return fetchThirdData(for: dataTuple)
}).then({
    ((data1, data2, data3)) in
    processData(data1, data2, data3)
}).rescue({
    reason in
    handleError(reason)
})
```

Here, in `fetchSecondData` and `fetchThirdData` custom promises are created. This is achieved by using `Promise<T>()` initializer and `resolve` and `reject` methods. These are the cornerstones for developing your own promise-based solutions.

A promise can be in three states: pending, fulfilled, and rejected. When a promise is created using `Promise<T>()`, it is in pending state, and it will remain in this state until `resolve` or `reject` is called on it. A promise by itself does nothing, it is simply a clever way to arrange your callbacks, so if you are creating custom promises, it is your solution's responsibility to `resolve` or `reject` them.

When `resolve` or `reject` is called on a pending promise, the promise transitions to the fulfilled or rekjected state respectively. In the fulfilled state the promise holds the value passed as an argument to `resolve`, and in the rejected state it has the rejection reason that was passed to `reject`. In the fulfilled or rejected state the promise is sealed and cannot transition to any other state.

After transitioning to the fulfilled state with a value `x`, the promise fires its `then` blocks with `x` as an argument. After the promise is rejected with an error, or after error is thrown from a `then` block, the promise invokes suitable `rescue` blocks with the error.

`rescue` is conditional. If you write e.g.
```Swift
Fetch.request(myRequest).then {
    data in
    doSomething(data)
} .rescue {
    loadError: FetchError in
    print("HTTP error")
}
```
only connection errors thrown by `Fetch.request(_:)` will be rescued, and custom errors thrown by `doSomething(_:)` will not.

See doc/Promise.md for a detailed specification on core `Promise<T>` methods.

To make life easier, `Promise<T>.resolve(_ value:)` and `Promise<T>.reject(_ reason:)` construct promises that are automatically resolved and rrejected respectively.

The initializer you will probably be mostly using is defined as follows
```Swift
public typealias Initializer = (@escaping (T) -> (), @escaping (Any?) -> ()) -> ()
public convenience init(_ initializer: @escaping Initializer) {
```
The `initializer` block's execution is deferred until later time (in current implementation it is scheduled asynchronously on the main dispatch queue), and the promise is created in pending state.
When `initializer` is called, the first parameter is the promise's `resolve`. and the second -- `reject` method.

Note the similarity between `fetchSecondData` and `fetchThirdData` in the example above. In fact, the task of passing down data with a promise would be so common, that the solution has been added to `Promise<T>`itself with the `&&&` operator.

Let us say you have `promise1: Promise<T1>` and `value2: T2`. Then `promise1 &&& value2` yields a `Promise<(T1, T2)>` that
- if `promise1` is resolved, is resolved with tuple value `(promise1.value!, value2)`;
- if `promise1` is rejected with some reason, is also rejected with the same reason.

The result of `value2 &&& promise1` will be similar, but with values in the opposite order: `(value2, promise1.value!)`.

You can also combine two promises with `&&&`. If `promise1: Promise<T1>`, `promise2: Promise<T2>`, and
```Swift
promise3: Promise<(T1, T2)> = promise1 &&& promise2
```
then
- if `promise1` or `promise2` is rejected with some reason, `promise3` is also rejected with the reason of the first rejected promise;
- if both `promise1` and `promise2` are fulfilled, `promise3` is fulfilled with tuple value `(promise1.value!, promise2.value!)`.

So, with `&&&` our example will look like
```Swift
fetch.request(request1).then(async: {
    data1 in
    let nextRequest = createSecondRequest(fromData: data1)
    return data1 &&& Fetch.request(nextRequest)
}).then(async: {
    ((data1, data2)) in
    let nextRequest = crreateThirdrequest(from: data2)
    return (data1, data2) &&& Fetch.request(nextRequest)
}).then({
    (((data1, data2), data3)) in
    processData(data1, data2, data3)
}).rescue({
    reason in
    handleError(reason)
})
```

There is also the `|||` operator for promises. If `promise1: Promise<T1>`, `promise2: Promise<T2>`, and
```Swift
promise3: Promise<Any> = promise1 ||| promise2
```
then
- if `promise1` or `promise2` is fulfilled with some value, `promise3` is also fulfilled with the value of the first fulfilled promise;
- if both `promise1` and `promise2` are rejected, `promise3` is rejected with tuple reason `(promise1.rejectReason, promise2.rejectReason)`.

> **Tip: use brackets to control the returned tuple structure**
> I.e. always write `(promise1 &&& promise2) &&& promise3`, not `promise1 &&& promise2 &&& promise3`
> -- this way you wouldn't be forced to always keep in mind the `&&&` associativity.

The `&&&` and `|||` operators provide a substitute for JavaScript [`Promise.all`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all) and [`Promise.race`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/race).

Because of type safety, exact equivalents would be much less useful than in JavaScript.

#### Promises and memory management

The best memory management rule for promises is probably **don't keep swift promises**.
Consider the following example:
```Swift
class MyClass {
    var promise: Promise<Data> = Promise<Data>()
    
    func processData() {
        guard .fulfilled == promise.state else {
            return
        }
        
        let data = promise.value!
        //Do something with data
    }
    
    init(request: URLRequest) {
        promise = Fetch.request(request).then {
            _ in
            //Memory leak!
            self.processData()
        }
    }
}
```
Here, because the promise keeps strong references to its `then` blocks, `MyClass` owns a promise, and `self` is captured in a `then` block, a retain cycle is created which results in a memory leak.

Of course, the cycle can be broken by weakly referencing `self` in a `then` handler, but it would be much better not to keep the reference to promise at all.

Because after a promise is fulfilled or rejected it cannot transition to any other state, the promise is essentially a one-time object, so a stored promise is of very limited use.

A promise should be treated as a transient object. A better implemetation of `MyClass` would be
```Swift
class MyClass {
    var data: Data?

    func processData() {
        guard nil != data else {
            return
        }

        let theData = data!
        //Do something with theData
    }

    init(request: URLRequest) {
        Fetch.request(request).then {
            data in
            //No memory leak here, even though self is captured
            self.data = data
            self.processData()
        }
    }
}
```

So who keeps the promise for you? Let is look inside `Fetch.request(_:)` implementation:
```Swift
class Fetch {
    class func request(_ request: URLRequest) -> Promise<Data> {
        let innerPromise = Promise<Data>()
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            guard nil == error else {
                innerPromise.reject(FetchError.connectionError)
                return
            }

            let code = (response as? HTTPURLResponse)?.statusCode ?? 400
            guard code <= 400 else {
                innerPromise.reject(FetchError.httpError(code))
                return
            }

            guard nil != data else {
                innerPromise.reject(FetchError.noData)
                return
            }

            innerPromise.resolve(data!)
        }

        let promise = Promise<Data>(discard: {
            [weak task] in
            task?.cancel()
        })

        promise.chain(after: innerPromise)
        task.resume()

        return promise
    }
}
```

Here `innerPromise` is captured by the `URLSessionTask` completion block. The returned promise is chained after `innerPromise`, i.e. when `innerPromise` is resolved/rejected, the chained promise will be resolved/rejected with the same value/reason (see doc/Promise.md 2.2). This also gives `innerPromise` ownership of the returned promise. Note the weak data task reference in the returned promise's discard block - it helps avoid a retain cycle.

So in this case the entire promise chain is owned by `Fetch` implementation. If you are using promises in your own solution, you should follow the same pattern. When wrapping a callback-based API in promises, capture promises in callbacks.
