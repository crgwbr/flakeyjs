#!/usr/bin/python

from bottle import route, run, static_file, request, abort

import simplejson
data_file = "notes.json"


@route('/api/Note', method="GET")
def list():
    try:
        notes_file = open(data_file, 'rU')
    except:
        return simplejson.dumps([])
    notes = notes_file.read()
    notes_file.close()
    return notes
    
@route('/api/Note/<guid>', method="GET")
def get(guid):
    try:
        notes_file = open(data_file, 'rU')
        notes = simplejson.loads(notes_file.read())
        notes_file.close()
    except:
        notes = []

    i = 0
    index = None
    for note in notes:
        if note['id'] == guid:
            index = i
        i += 1

    if index == None:
        abort(404)
    else:
        return simplejson.dumps(notes[index])
    
@route('/api/Note/<guid>', method="POST")
def post(guid):
    try:
        notes_file = open(data_file, 'rU')
        notes = simplejson.loads(notes_file.read())
        notes_file.close()
    except:
        notes = []
    
    i = 0
    index = None
    for note in notes:
        if note['id'] == guid:
            index = i
        i += 1
    
    obj = {
        'versions': simplejson.loads(request.POST.versions),
        'id': guid
    }
    if index == None:
        notes.append(obj)
    else:
        notes[index] = obj
    
    notes_file = open(data_file, 'w')
    notes_file.write(simplejson.dumps(notes))
    notes_file.close()
    return simplejson.dumps(obj)
    
@route('/api/Note/<guid>', method="DELETE")
def delete(guid):
    try:
        notes_file = open(data_file, 'rU')
        notes = simplejson.loads(notes_file.read())
        notes_file.close()
    except:
        notes = []
    
    i = 0
    index = None
    for note in notes:
        if note['id'] == guid:
            index = i
        i += 1
    
    deleted = {}
    if index != None:
        deleted = notes[index]
        del notes[index]
    
    notes_file = open(data_file, 'w')
    notes_file.write(simplejson.dumps(notes))
    notes_file.close()
    return simplejson.dumps(deleted)

@route('/')
def index():
    return static_file('index.html', root='public/')

@route('<filename:path>')
def static(filename):
    return static_file(filename, root='public/')
    
    
run(host='0.0.0.0', port=8080, reloader=True)