## Building Apps with Flakey.js
Flakey.js is written in CoffeeScript and makes heavy use of it's Class structure and simulated classical inheritance. As such, it's easiest to write Flakey.js apps in CoffeeScript, using the `Class` and `extends` features. 

Additionally, throughout the examples in these docs we use eco html templates as views and browserify to take care of bundling dependancies into a single Javascript file. Neither of these are required or part of Flakey.js, but they do work nicely.


## Compiling Flakey.js
##### Requirements

To compile Flakey.js from source, you'll need to install:

- [nodejs](http://nodejs.org/#download)
- npm (normally installed with nodejs)
- cake (normally installed with nodejs)
- coffeescript (`npm install -g coffee-script`)

To compile the sample note taking app (example/*), all of the above plus:

- browserify (`npm install browserify`)
- eco (`npm install -g eco`)

##### Build Process
To compile Flakey.js, cd to the root of the repository and run: `cake build`. That will concat the files in `src/` into flakey.coffee. Then flakey.coffee is compiled into flakey.js, and finally minified into flakey.min.js using Google's closure compiler.