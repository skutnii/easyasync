# easyswift
This is a library of some useful Swift code I wrote initially in the context of a test task for a job interview. In the process, i developed a couple of interesting solutions to common iOS programming problems.

Then I have extracted the things that I feel make life a lot easier into this package.

Current version in development is pre-alpha, 0.1.0.

Features planned for 0.1.0:
+ Promises thoroughly documented (see the specification at doc/Promise.md) and unit tested.
+ Fetch undocumented but useful.
+ JSQ in its embryonic state.
+ WebImage and Observable somewhat usable.

## Usage tips

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

#### `resolve`, `reject`, and promise operators

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
```
