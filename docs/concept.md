# Flakey.js
**Goal:** A Javascript MVC framework with an emphasis on Model reliability. Flakey.js would be targeted towards mobile platforms where solid server connections are not often possible.

**Details:**

- Models that exist as heuristic, versioned instructions rather than complete "records."  Therefore instead of a model instance being essentially a JS object with data parameters, data would be stored as a series of transactional modifications, dating back to the models creation. This has several benefits: all data is intrinsically versioned and backed up. Any transaction can be rolled back, and history can easily be viewed.

- When modified, a model will push a transaction onto a pending transaction log for each persistence method. For example, if a model is to be stored in localStorage & on on a server, a pending transaction log will exist for both localStorage and server storage.

- When a persistence method (localStorage or server storage) detect that there is a pending transaction, it attempt to apply that transaction to its data. For example, if server storage detects that it needs to "UPDATE Document SET x=2 WHERE id=3", it will attempt to apply this transaction to the server by sending the appropriate HTTP-REST requests. If it succeeds, then the that transaction is popped from the pending transaction log. If it fails, it remains in the pending transaction log to be attempted again in a few minutes.  The same model will be used for localStorage, even though a transaction should theoretically never fail.
