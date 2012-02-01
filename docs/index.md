#### What's Flakey.js?
Flakey.js is a (yet another) Javascript MVC framework with an emphasis on Model reliability. Flakey.js is targeted towards mobile platforms where solid server connections are not often possible.

Traditionally working with data inside a web app, for example writing an email or long document, can be dangerous when the internet connection is intermittent. Entire documents can easily be lost. Flakey.js aims to fix this.

* * * * *

#### Why shouldn't I just use [ligament.js](https://gist.github.com/313496e6ba9160dc6eb5)?
Unlike most Javascript MVC frameworks, data in Flakey.js is more than just a hash table representing the models most current state. Instead, a model exists as a set of instructions on how to build it's most current state. Therefore, any transaction of change in the model can be rolled back, and history can easily be viewed. This is ideal for applications with relatively small datasets (note taking apps, personal wiki's, todo lists) where the data itself is more important than raw performance.