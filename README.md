# Flakey.js

### Whats Flakey.js
**Goal:** A Javascript MVC framework with an emphasis on Model reliability. Flakey.js is targeted towards mobile platforms where solid server connections are not often possible.

**Details:**
Models exist as heuristic, versioned instructions rather than complete "records."  Therefore instead of a model instance being essentially a JS object with data parameters, data is be stored as a series of transactional modifications, dating back to the models creation. This has several benefits: all data is intrinsically versioned and backed up. Any transaction can be rolled back, and history can easily be viewed.

### Building an app based on Flakey.js
Using browserify to add requirement support to client side code (like the included example app) is strongly recommended. However it is possible to use Flakey.js as a vanilla JS file.

### Requirements
- node
- coffeescript
- browserify
- eco

### Notes:
flakey.js includes jQuery-1.7.1. To change this, you must replace src/lib/jquery.coffee and recompile flakey.js from source.