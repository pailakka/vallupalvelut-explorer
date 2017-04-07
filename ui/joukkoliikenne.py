import os
import tornado.auth
import tornado.httpserver
import tornado.ioloop
import tornado.options
import tornado.web
from tornado.web import url
#import sqlite3

import psycopg2
import psycopg2.extensions
psycopg2.extensions.register_type(psycopg2.extensions.UNICODE)
psycopg2.extensions.register_type(psycopg2.extensions.UNICODEARRAY)
from psycopg2.pool import ThreadedConnectionPool
import codecs

import handlers.index
import handlers.reitit
import handlers.pysakit
#import handlers.map

import string
import math

from tornado.options import define, options

define("port", default=8888, help="run on the given port", type=int)
define("dbuser", help="DB user", type=str)
define("dbpasswd", help="DB password", type=str)
define("dbname", help="DB name", type=str)
define("dbhost", default='localhost', help="DB host", type=str)
define("dbport", default=5432, help="DB port", type=int)



def dict_factory(cursor, row):
    d = {}
    for idx, col in enumerate(cursor.description):
        d[col[0]] = row[idx]
    return d


class Application(tornado.web.Application):
    def __init__(self):
        routes = [
            url(r"/joukkoliikenne/katselu/", handlers.reitit.IndexHandler,name='index'),
            url(r"/joukkoliikenne/katselu/reitit", handlers.reitit.IndexHandler,name='reitit'),
            url(r"/joukkoliikenne/katselu/reitit/kautta", handlers.reitit.KauttaHandler,name='reitit.kautta'),
            url(r"/joukkoliikenne/katselu/reitit/matriisi", handlers.reitit.MatriisiHandler,name='reitit.matriisi'),
            url(r"/joukkoliikenne/katselu/reitti/([\d]*)$", handlers.reitit.ReittiHandler,name='reitit.reitti'),
            url(r"/joukkoliikenne/katselu/pysakit", handlers.pysakit.IndexHandler,name='pysakit'),
            url(r"/joukkoliikenne/katselu/pysakit/lahella", handlers.pysakit.NearHandler,name='pysakit.lahella'),
            #(r"/map", handlers.map.MapBaseHandler),
        ]
        settings = dict(
            template_path=os.path.join(os.path.dirname(__file__), "templates"),
            static_path=os.path.join(os.path.dirname(__file__), "static"),
            xsrf_cookies=True,
            debug=True,
            static_url_prefix='/joukkoliikenne/static/'
        )
        tornado.web.Application.__init__(self, routes, **settings)

        #self.dbconn = sqlite3.connect('../db/cgi_20151130.db')
        #self.dbconn.row_factory = dict_factory


        #self.dbconn.create_function("hypot", 2, math.hypot)
        assert options.dbhost
        assert options.dbport
        assert options.dbname
        assert options.dbuser
        assert options.dbpasswd
        self.dbconn = ThreadedConnectionPool(1,5,host=options.dbhost,port=options.dbport,dbname=options.dbname,user=options.dbuser,password=options.dbpasswd)

        self.kuntanumerot = {}
        f = codecs.open('/home/peltonent/jltikku/db/kuntanumerot.txt','r','utf-8')
        for l in f:
            l = map(string.strip,l.strip().split('\t'))
            self.kuntanumerot[int(l[0])] = l[1]
        f.close()
def main():
    tornado.options.parse_command_line()
    http_server = tornado.httpserver.HTTPServer(Application())
    http_server.listen(options.port)
    tornado.ioloop.IOLoop.instance().start()


if __name__ == "__main__":
    main()
