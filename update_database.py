#import wget
import shapefile

import psycopg2
import psycopg2.extensions
psycopg2.extensions.register_type(psycopg2.extensions.UNICODE)
psycopg2.extensions.register_type(psycopg2.extensions.UNICODEARRAY)

import os
import shutil
import unicodecsv
import codecs
import pprint
from dateutil.parser import parse
import zipfile
import cStringIO
import requests

import datetime

import sys

import rtree
import shapely.wkb as wkb
from shapely.geometry import Point,LineString
from shapely.prepared import prep
try:
  import shapely.speedups
  shapely.speedups.enable()
except:
  print 'No speedups'


script_path = os.path.dirname(os.path.realpath(__file__))
temp_path = os.path.realpath(os.path.join(script_path,'temp'))

kuntajako_index = rtree.index.Rtree(os.path.join(script_path,'kuntajako_tm35'))
kuntajako = {}
f = codecs.open(os.path.join(script_path,'kuntajako_tm35_info.dat'),'rb','utf-8')
for l in f:
    kid,nimi,geom = l.strip().split(';')
    kuntajako[int(kid)] = (nimi,prep(wkb.loads(geom.decode('hex'))))

f.close()
print 'Kuntajako loaded'

if len(sys.argv) == 1:
    if os.path.exists(temp_path):
        shutil.rmtree(temp_path)

    os.mkdir(temp_path)

    urls = (
    ('https://koontikartta.navici.com/tiedostot/vuoro.csv','vuoro.csv'),
    ('https://koontikartta.navici.com/tiedostot/pysakkiketjut.zip','pysakkiketjut.zip'),
    ('https://koontikartta.navici.com/tiedostot/linjaukset.zip','linjaukset.zip'),
    )
    for url,dest in urls:
        r = requests.get(url,stream=True)
        print 'Downloading file',dest
        totl = lp = 0
        cl = float(int(r.headers['Content-Length']))
        with open(os.path.join(temp_path,dest),'wb') as f:
            for chunk in r.iter_content(chunk_size=1024):
                if chunk:
                    f.write(chunk)
                    t = f.tell()
                    p = t-lp
                    totl+=p
                    lp = t
                    if totl/cl > 0.05:
                        totl=0
                        sys.stdout.write('.')
                        sys.stdout.flush()
        print
        print 'Done'
print 'Database update started',datetime.datetime.now()

dbhost = os.environ.get('DBHOST','localhost')
dbport = os.environ.get('DBPORT','5432')
dbname = os.environ.get('DBNAME','joukkoliikenne')
dbuser = os.environ.get('DBUSER')
dbpasswd = os.environ.get('DBPASSWD')

dbport = int(dbport)

assert dbhost
assert dbport
assert dbname
assert dbuser
assert dbpasswd

conn = psycopg2.connect(host=dbhost,port=dbport,dbname=dbname,user=dbuser,password=dbpasswd)
curs = conn.cursor()

#curs.execute('TRUNCATE TABLE vuorot;');
#curs.execute('TRUNCATE TABLE pysakkiketjut;');
#curs.execute('TRUNCATE TABLE pysakit;');
curs.execute('DELETE FROM vuorot;');
curs.execute('DELETE FROM pysakkiketjut;');
curs.execute('DELETE FROM pysakit;');
curs.execute('DELETE FROM linjaukset;');
curs.close()
conn.commit()


if True:
    print 'Vuorot'
    curs = conn.cursor()
    i = 0
    vuorot_sqlq = '''INSERT INTO vuorot
                (lu_viranro_myontaa,viranomaisnimi,lu_viranro_valvoo,viranomaisnimi_1,lu_voim_pvm,lu_lop_pvm,lu_tod_loppvm,lupasoptunnus,muokattu_pvm,liikharjnro,liikharj_nimi,reittinro_pysyva,reittinimi,ajosuunta,linjan_tunnus,reitti_voimaan_pvm,reitti_paattyy_pvm,reittia_muokattu_pvm,vuorotunniste_pysyva,vuoromerk,lahtoaika,perilla,kausi,vuorotyyppi,vuoro_lisatunniste,vuoro_voimaan_pvm,vuoro_paattyy_pvm,vuoroa_muokattu_pvm,kasitelty_koontikartassa,siirtyy_matka_fi,vuoron_url_interpoloitu)
                VALUES
                (%(lu_viranro_myontaa)s,%(viranomaisnimi)s,%(lu_viranro_valvoo)s,%(viranomaisnimi_1)s,%(lu_voim_pvm)s,%(lu_lop_pvm)s,%(lu_tod_loppvm)s,%(lupasoptunnus)s,%(muokattu_pvm)s,%(liikharjnro)s,%(liikharj_nimi)s,%(reittinro_pysyva)s,%(reittinimi)s,%(ajosuunta)s,%(linjan_tunnus)s,%(reitti_voimaan_pvm)s,%(reitti_paattyy_pvm)s,%(reittia_muokattu_pvm)s,%(vuorotunniste_pysyva)s,%(vuoromerk)s,%(lahtoaika)s,%(perilla)s,%(kausi)s,%(vuorotyyppi)s,%(vuoro_lisatunniste)s,%(vuoro_voimaan_pvm)s,%(vuoro_paattyy_pvm)s,%(vuoroa_muokattu_pvm)s,%(kasitelty_koontikartassa)s,%(siirtyy_matka_fi)s,%(vuoron_url_interpoloitu)s)'''
    execlist = []
    with open(os.path.join(temp_path,'vuoro.csv'),'rb') as f:
        csvf = unicodecsv.reader(f, delimiter=';', quotechar='"',encoding='utf-8-sig')
        header = False
        for l in csvf:
            if not header:
                l[0] = l[0].replace('"','')
                header = l
                continue
            l = dict(zip(header,l))

            for k in (u'siirtyy_matka_fi',u'kasitelty_koontikartassa'):
                l[k] = l[k] == u'kyll\xe4'

            for k in header:
                if k.endswith('pvm'):
                    if l[k] == '':
                        l[k] = None
                    else:
                        l[k] = parse(l[k])

            for k in (u'liikharjnro',u'reittinro_pysyva',u'vuoro_lisatunniste',u'vuorotunniste_pysyva'):
                l[k] = int(l[k])
            #pprint.pprint(l)
            execlist.append(l)
            if i % 1000 == 0:
                curs.executemany(vuorot_sqlq,execlist)
                execlist = []
                print i
            i+=1
    curs.executemany(vuorot_sqlq,execlist)
    curs.close()
    conn.commit()


pysakit = {}
if True:
    print 'Pysakkiketjut'
    curs = conn.cursor()
    execlist = []

    pysakkiketjut_sql = 'INSERT INTO pysakkiketjut (vuoro_lisa,vuoro_pys,jarj_nro,saapumisa,lahtoaika,aikapiste,etaisyys,pysakki_gid) VALUES (%(VUORO_LISA)s,%(VUORO_PYS)s,%(JARJ_NRO)s,%(SAAPUMISA)s,%(LAHTOAIKA)s,%(AIKAPISTE)s,%(ETAISYYS)s,%(PYSAKKI_ID)s)'
    with zipfile.ZipFile(os.path.join(temp_path,'pysakkiketjut.zip')) as zf:

        shpf = cStringIO.StringIO(zf.read('pysakkiketjut.shp'))
        dbff = cStringIO.StringIO(zf.read('pysakkiketjut.dbf'))
        sf = shapefile.Reader(shp=shpf, dbf=dbff)

        headers = [f[0] for f in sf.fields[1:]]
        i = 0
        for sr in sf.iterShapeRecords():
            r = dict(zip(headers,sr.record))
            x,y = map(lambda v: round(v,1),sr.shape.points[0])

            r['NIMI'] = r['NIMI'].decode('utf-8')
            r['AIKAPISTE'] = r['AIKAPISTE'] == 1
            pk = (r['ID'],r['NIMI'],x,y)
            r['SAAPUMISA'] = datetime.timedelta(**dict(zip(('hours','minutes'),map(int,(r['SAAPUMISA'].split(':'))))))
            r['LAHTOAIKA'] = datetime.timedelta(**dict(zip(('hours','minutes'),map(int,(r['LAHTOAIKA'].split(':'))))))
            if not pk in pysakit:
                gid = len(pysakit)
                pysakit[pk] = {'nimi':r['NIMI'],'valtakid':r['ID'],'gid':gid,'x':x,'y':y}
                r['PYSAKKI_ID'] = gid
            else:
                r['PYSAKKI_ID'] = pysakit[pk]['gid']

            #curs.execute('INSERT INTO pysakkiketjut (vuoro_lisa,vuoro_pys,jarj_nro,saapumisa,lahtoaika,aikapiste,etaisyys,pysakki_gid) VALUES (%(VUORO_LISA)s,%(VUORO_PYS)s,%(JARJ_NRO)s,%(SAAPUMISA)s,%(LAHTOAIKA)s,%(AIKAPISTE)s,%(ETAISYYS)s,%(PYSAKKI_ID)s)',r)
            execlist.append(r)
            if i % 10000 == 0:
                curs.executemany(pysakkiketjut_sql,execlist)
                execlist = []
                print i
            i+=1
    curs.executemany(pysakkiketjut_sql,execlist)
    curs.close()
    conn.commit()


if True:
    print 'Linjaukset'
    curs = conn.cursor()
    execlist = []

    linjaukset_sql = 'INSERT INTO linjaukset (vuoro_lisa,tyyppi,geom) VALUES (%(VUORO_LISA)s,%(TYYPPI)s,ST_SetSRID(ST_GeomFromWKB(decode(%(geomwkb)s,\'hex\')),3067))'
    with zipfile.ZipFile(os.path.join(temp_path,'linjaukset.zip')) as zf:

        shpf = cStringIO.StringIO(zf.read('linjaukset.shp'))
        dbff = cStringIO.StringIO(zf.read('linjaukset.dbf'))
        sf = shapefile.Reader(shp=shpf, dbf=dbff)

        headers = [f[0] for f in sf.fields[1:]]
        i = 0
        for sr in sf.iterShapeRecords():
            r = dict(zip(headers,sr.record))
            #x,y = map(lambda v: round(v,1),sr.shape.points[0])


            ls = LineString(sr.shape.points)
            ls = ls.simplify(2.0)

            r['geomwkb'] = wkb.dumps(ls).encode('hex')

            #curs.execute('INSERT INTO pysakkiketjut (vuoro_lisa,vuoro_pys,jarj_nro,saapumisa,lahtoaika,aikapiste,etaisyys,pysakki_gid) VALUES (%(VUORO_LISA)s,%(VUORO_PYS)s,%(JARJ_NRO)s,%(SAAPUMISA)s,%(LAHTOAIKA)s,%(AIKAPISTE)s,%(ETAISYYS)s,%(PYSAKKI_ID)s)',r)
            execlist.append(r)
            if i % 1000 == 0:
                curs.executemany(linjaukset_sql,execlist)
                execlist = []
                print i
            i+=1
    curs.executemany(linjaukset_sql,execlist)
    curs.close()
    conn.commit()



curs = conn.cursor()
print 'Pysakit'
i = 0
for k in pysakit:
    p = pysakit[k]
    if not 'id' in p:
        p['id'] = None

    geom = Point(p['x'],p['y'])
    kuntanro = None
    idxinters = list(kuntajako_index.intersection(geom.bounds))
    #pprint.pprint(p)
    #print idxinters,geom,geom.bounds
    for idx in idxinters:
      if kuntajako[idx][1].intersects(geom):
        kuntanro = idx
        break
    p['kuntanro'] = kuntanro
    curs.execute('INSERT INTO pysakit (gid,valtakid,nimi,kuntanro,x,y,geom) VALUES (%(gid)s,%(valtakid)s,%(nimi)s,%(kuntanro)s,%(x)s,%(y)s,ST_SetSRID(ST_Point(%(x)s,%(y)s),3067))',p)
    if i % 1000 == 0:
        print len(pysakit),i
    i+=1
conn.commit()
curs.close()


#shutil.rmtree(temp_path)

print 'Database update done',datetime.datetime.now()
'''

CREATE TABLE pysakkiketjut
(
  gid serial NOT NULL,
  vuoro_lisa integer,
  vuoro_pys integer,
  jarj_nro integer,
  saapumisa character varying(5),
  lahtoaika character varying(5),
  aikapiste boolean,
  etaisyys integer,
  nimi character varying(56),
  id integer,
  x double precision,
  y double precision,
  CONSTRAINT pysakkiketjut_pkey PRIMARY KEY (gid)
)


CREATE TABLE vuorot
(
  lu_viranro_myontaa character varying(5),
  viranomaisnimi text,
  lu_viranro_valvoo character varying(5),
  viranomaisnimi_1 text,
  lu_voim_pvm timestamp without time zone,
  lu_lop_pvm timestamp without time zone,
  lu_tod_loppvm timestamp without time zone,
  lupasoptunnus character varying(20),
  muokattu_pvm timestamp without time zone,
  liikharjnro integer,
  liikharj_nimi text,
  reittinro_pysyva integer,
  reittinimi text,
  ajosuunta character varying(5),
  linjan_tunnus character varying(255),
  reitti_voimaan_pvm timestamp without time zone,
  reitti_paattyy_pvm timestamp without time zone,
  reittia_muokattu_pvm timestamp without time zone,
  vuorotunniste_pysyva integer,
  vuoromerk character varying(10),
  lahtoaika character varying(4),
  perilla character varying(4),
  kausi character varying(10),
  vuorotyyppi text,
  vuoro_lisatunniste integer NOT NULL,
  vuoro_voimaan_pvm timestamp without time zone,
  vuoro_paattyy_pvm timestamp without time zone,
  vuoroa_muokattu_pvm timestamp without time zone,
  kasitelty_koontikartassa boolean,
  siirtyy_matka_fi boolean,
  vuoron_url_interpoloitu text
)

'''
