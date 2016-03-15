from base import BaseHandler
import json
import pprint
import string
import datetime
import math
import csv
import cStringIO
from operator import itemgetter

date_handler = lambda obj: (
    obj.isoformat()
    if isinstance(obj, datetime.datetime)
    or isinstance(obj, datetime.date)
    else None
)


class IndexHandler(BaseHandler):
    def get(self):
        self.render2('reitti_index')

    def post(self):

        comp = self.get_argument('company',None)
        sopim = self.get_argument('sopimus',None)
        reitti = self.get_argument('reitti',None)
        vuoro = self.get_argument('vuoro',None)
        reitit = []

        curs = self.cursor

        sqlq = 'SELECT DISTINCT reittinro_pysyva as reittiid,lupasoptunnus,liikharjnro,liikharj_nimi,reittinimi,reitti_voimaan_pvm,reitti_paattyy_pvm,reittia_muokattu_pvm,(SELECT COUNT(*) FROM vuorot v WHERE v.reittinro_pysyva = vs.reittinro_pysyva) as vuoromaara,vuorotyyppi,(SELECT MIN(vuoron_url_interpoloitu) FROM vuorot v3 WHERE v3.reittinro_pysyva = vs.reittinro_pysyva) as vuoron_url_interpoloitu FROM vuorot vs'

        params = {}

        if comp or sopim or reitti or vuoro:
            filters = []
            if comp:
                filters.append('(liikharjnro::varchar ILIKE %(comp)s OR liikharj_nimi ILIKE %(comp)s)')
                params['comp'] = u'%' + unicode(comp) + u'%'
            if sopim:
                filters.append('(lupasoptunnus ILIKE %(sopim)s)')
                params['sopim'] = '%' + sopim + '%'

            if reitti:
                filters.append('(reittinro_pysyva::varchar ILIKE %(reitti)s OR reittinimi ILIKE %(reitti)s)')
                params['reitti'] = '%' + reitti + '%'

            if vuoro:
                filters.append('(reittinro_pysyva IN (SELECT v2.reittinro_pysyva FROM vuorot v2 WHERE v2.vuorotunniste_pysyva=%(vuoro)s OR v2.vuoro_lisatunniste = %(vuoro)s))')
                params['vuoro'] = vuoro

            sqlq += ' WHERE %s' % (' AND ' if self.get_argument('type','and') == 'and' else ' OR ').join(filters)

        sqlq += ' ORDER BY lupasoptunnus,reittinro_pysyva;'
        #self.write(repr(sqlq))
        #self.write('\n')
        #self.write(pprint.pformat(params))
        #self.write('\n')
        #return None

        #self.write(repr(curs.mogrify(sqlq,params)))
        curs.execute(sqlq,params)

        reitit = curs.fetchall()
        if self.get_argument('format','tpl') == 'json':
            self.write(json.dumps(reitit, default=date_handler))
        else:
            self.render2('reitti_index',reitit=reitit)

class KauttaHandler(BaseHandler):
    def get(self):
        self.render2('reitti_kautta')

    def post(self):
        curs = self.cursor

        stations = self.get_argument('stations','')

        stations = stations.strip().split(',')
        filter(lambda s: len(s) > 0 and s[1:].isdigit(),stations)

        if len(stations) == 0:
            if self.get_argument('format','tpl') == 'json':
                self.write(json.dumps({'error':'Stationlist empty'}))
            else:
                self.write('Ei asemia listattuna')
            return None


        stations = [int(s) for s in stations if s.isdigit()]
        format = self.get_argument('format','tpl')

        if format != 'csv':
            sqlq = ('SELECT DISTINCT reittinro_pysyva as reittiid,lupasoptunnus,liikharjnro,liikharj_nimi,reittinimi,reitti_voimaan_pvm,reitti_paattyy_pvm,reittia_muokattu_pvm,(SELECT COUNT(*) FROM vuorot v WHERE v.reittinro_pysyva = vs.reittinro_pysyva) as vuoromaara,vuorotyyppi,(SELECT MIN(vuoron_url_interpoloitu) FROM vuorot v2 WHERE v2.reittinro_pysyva=vs.reittinro_pysyva) as vuoron_url_interpoloitu FROM vuorot vs WHERE vs.vuoro_lisatunniste IN (SELECT pk.vuoro_lisa FROM pysakkiketjut pk WHERE pk.pysakki_gid IN %s) ORDER BY vs.lupasoptunnus,vs.reittinro_pysyva')
        else:
            sqlq = ('SELECT vs.* FROM vuorot vs WHERE vs.vuoro_lisatunniste IN (SELECT pk.vuoro_lisa FROM pysakkiketjut pk WHERE pk.pysakki_gid IN %s)')
        if len(stations) == 0:
            stations = [None,]
        curs.execute(sqlq,(tuple(stations),))

        reitit = curs.fetchall()
        if format == 'json':
            self.write(json.dumps(reitit, default=date_handler))
        elif format == 'csv':
            columns = ('lu_viranro_myontaa','viranomaisnimi','lu_viranro_valvoo','viranomaisnimi_1','lu_voim_pvm','lu_lop_pvm','lu_tod_loppvm','lupasoptunnus','muokattu_pvm','liikharjnro','liikharj_nimi','reittinro_pysyva','reittinimi','ajosuunta','linjan_tunnus','reitti_voimaan_pvm','reitti_paattyy_pvm','reittia_muokattu_pvm','vuorotunniste_pysyva','vuoromerk','lahtoaika','perilla','kausi','vuorotyyppi','vuoro_lisatunniste','vuoro_voimaan_pvm','vuoro_paattyy_pvm','vuoroa_muokattu_pvm','kasitelty_koontikartassa','siirtyy_matka_fi','vuoron_url_interpoloitu')
            csvfile = cStringIO.StringIO()
            vuorocsvwriter = csv.DictWriter(csvfile, delimiter=';',quotechar='"', quoting=csv.QUOTE_NONNUMERIC,fieldnames=columns)
            vuorocsvwriter.writeheader()
            for vuoro in reitit:
                vuorocsvwriter.writerow({k:v.encode('utf8') if isinstance(v,basestring) else v for k,v in vuoro.items()})

            csvfile.seek(0)
            self.set_header("Content-Type", 'text/csv')
            self.set_header("Content-Disposition", "attachment; filename=vuorot.csv")
            self.write(csvfile.read())
            csvfile.close()
        else:
            self.render2('reitti_index',reitit=reitit)

        #self.write(pprint.pformat(stations))

class MatriisiHandler(BaseHandler):
    def get(self):

        self.render2('reitti_matriisi',kuntanumerot=json.dumps(self.application.kuntanumerot))

    def post(self):
        curs = self.cursor

        args = self.request.arguments


        format = self.get_argument('format','tpl')

        matrix = []
        muncipfilters = []
        for ak in args.keys():
            if not ak.startswith('selpys'):
                continue
            matrix.append(tuple(( int(gid) for gid in map(string.strip,args[ak][0].strip().split(',')) if gid != '')))
            muncipfilters.append(tuple((int(kid) for kid in map(string.strip,(args['muncip_' + ak][0].strip().split(',')) if args.has_key('muncip_' + ak) else None) if kid != '')))



        for i in xrange(len(matrix)):
            if len(matrix[i]) == 0:
                matrix[i] = (None,)

            if len(muncipfilters[i]) == 0:
                muncipfilters[i] = (None,)

        if format != 'csv':
            sqlq = ('SELECT DISTINCT reittinro_pysyva as reittiid,lupasoptunnus,liikharjnro,liikharj_nimi,reittinimi,reitti_voimaan_pvm,reitti_paattyy_pvm,reittia_muokattu_pvm,(SELECT COUNT(*) FROM vuorot v WHERE v.reittinro_pysyva = vs.reittinro_pysyva) as vuoromaara,vuorotyyppi,(SELECT MIN(vuoron_url_interpoloitu) FROM vuorot v2 WHERE v2.reittinro_pysyva = vs.reittinro_pysyva) as vuoron_url_interpoloitu FROM vuorot vs WHERE vs.vuoro_lisatunniste IN (SELECT vuoro_lisa FROM pysakkiketjut WHERE pysakki_gid IN %s OR pysakki_gid IN (SELECT gid FROM pysakit WHERE kuntanro IN %s)) AND vs.vuoro_lisatunniste IN (SELECT vuoro_lisa FROM pysakkiketjut WHERE  pysakki_gid IN %s OR pysakki_gid IN (SELECT gid FROM pysakit WHERE kuntanro IN %s)) ORDER BY lupasoptunnus, reittiid;')
        else:
            sqlq = ('SELECT vs.* FROM vuorot vs WHERE vs.vuoro_lisatunniste IN (SELECT vuoro_lisa FROM pysakkiketjut WHERE pysakki_gid IN %s OR pysakki_gid IN (SELECT gid FROM pysakit WHERE kuntanro IN %s)) AND vs.vuoro_lisatunniste IN (SELECT vuoro_lisa FROM pysakkiketjut WHERE  pysakki_gid IN %s OR pysakki_gid IN (SELECT gid FROM pysakit WHERE kuntanro IN %s)) ORDER BY lupasoptunnus, reittinro_pysyva, vuoro_lisatunniste;')

        queryparams = (matrix[0],muncipfilters[0],matrix[1],muncipfilters[1])
        '''
        self.write(pprint.pformat(sqlq))
        self.write('\n')
        self.write(pprint.pformat(queryparams))
        self.write('\n')
        #return

        self.write(repr(curs.mogrify(sqlq,queryparams)))
        return
        #'''
        curs.execute(sqlq,queryparams)
        reitit = curs.fetchall()
        if format == 'json':
            self.write(json.dumps(reitit, default=date_handler))
        elif format == 'csv':
            columns = ('lu_viranro_myontaa','viranomaisnimi','lu_viranro_valvoo','viranomaisnimi_1','lu_voim_pvm','lu_lop_pvm','lu_tod_loppvm','lupasoptunnus','muokattu_pvm','liikharjnro','liikharj_nimi','reittinro_pysyva','reittinimi','ajosuunta','linjan_tunnus','reitti_voimaan_pvm','reitti_paattyy_pvm','reittia_muokattu_pvm','vuorotunniste_pysyva','vuoromerk','lahtoaika','perilla','kausi','vuorotyyppi','vuoro_lisatunniste','vuoro_voimaan_pvm','vuoro_paattyy_pvm','vuoroa_muokattu_pvm','kasitelty_koontikartassa','siirtyy_matka_fi','vuoron_url_interpoloitu')
            csvfile = cStringIO.StringIO()
            vuorocsvwriter = csv.DictWriter(csvfile, delimiter=';',quotechar='"', quoting=csv.QUOTE_NONNUMERIC,fieldnames=columns)
            vuorocsvwriter.writeheader()
            for vuoro in reitit:
                vuorocsvwriter.writerow({k:v.encode('utf8') if isinstance(v,basestring) else v for k,v in vuoro.items()})

            csvfile.seek(0)
            self.set_header("Content-Type", 'text/csv')
            self.set_header("Content-Disposition", "attachment; filename=vuorot.csv")
            self.write(csvfile.read())
            csvfile.close()
        else:
            self.render2('reitti_matriisi',reitit=reitit,kuntanumerot=json.dumps(self.application.kuntanumerot))



class ReittiHandler(BaseHandler):
    def get(self,reittiid):
        curs = self.cursor
        assert reittiid.isdigit()

        reittiid = int(reittiid)

        curs.execute('SELECT vs.* FROM vuorot vs WHERE vs.reittinro_pysyva = %s ORDER BY vs.vuorotunniste_pysyva',(reittiid,))

        midnight = datetime.datetime.now().replace(hour=0,minute=0,second=0,microsecond=0)

        vuorot = curs.fetchall()
        for v in vuorot:
            curs.execute('SELECT pk.*,p.* FROM pysakkiketjut pk LEFT JOIN pysakit p ON pk.pysakki_gid=p.gid WHERE pk.vuoro_lisa = %s ORDER BY jarj_nro ASC',(v['vuoro_lisatunniste'],))
            stops = curs.fetchall()

            os = None
            for s in stops:
                s['arrivaldt'] = midnight+s['saapumisa']
                s['departuredt'] = midnight+s['lahtoaika']
                s['city'] = '-'#self.application.kuntanumerot[int(s['cityid'])]
                if not os:
                    os = s
                    s['nk'] = None
                    continue

                s['nk'] = (int(os['jarj_nro']),int(s['jarj_nro']))
                #if s['gid'].startswith('D_'):
                #    s['name'] = s['name'][:-2] + s['name'][-2:].replace(' *','')
                #    s['gid'] = s['gid'][2:]

                os = s

            v['stops'] = stops

            #curs.execute('SELECT f.firstdate,f.vector FROM footnotes f WHERE footnoteid = ?',(v['footnoteid'],))
            #v['footnote'] = curs.fetchone()

            #curs.execute('SELECT t.name FROM service_trnsattr st LEFT JOIN trnsattr t ON st.trnsattrid=t.trnsattrid WHERE st.serviceid=?',(v['serviceid'],))
            #v['trnsattr'] = curs.fetchall()
            v['has_stops'] = len(stops) > 0
            v['departure'] = datetime.datetime(9999,1,1)
            if len(stops) > 0:
                v['departure'] = stops[0]['departuredt']
                v['kesto'] = stops[-1]['departuredt'] - stops[0]['arrivaldt']

        vuorot.sort(key=itemgetter('departure','vuoro_lisatunniste'))
        reittidata = {}
        for k in ('liikharj_nimi','liikharjnro','lu_tod_loppvm','lu_viranro_valvoo','lu_voim_pvm','lupasoptunnus','muokattu_pvm','reitti_paattyy_pvm','reitti_voimaan_pvm','reittia_muokattu_pvm','reittinro_pysyva','reittinimi','viranomaisnimi_1','lu_viranro_myontaa','viranomaisnimi'):
            reittidata[k] = vuorot[0][k]

        nopeudet = {}
        kaudet = {}
        etaisyydet = {}
        for v in vuorot:
            os = None
            for s in v['stops']:
                if os == None:
                    os = s
                    continue
                npk = (int(os['jarj_nro']),int(s['jarj_nro']))
                etaisyydet[npk] = (s['etaisyys']-os['etaisyys'])/1000.0#math.hypot(float(os['x'])-float(s['x']),float(os['y'])-float(s['y']))/1000.0

                if not nopeudet.has_key(npk):
                    nopeudet[npk] = {}
                td = int((s['arrivaldt']-os['departuredt']).total_seconds()/60)

                if v['kausi'] not in nopeudet[npk].keys():
                    nopeudet[npk][v['kausi']] = {}
                    kaudet[v['kausi']] = set([])
                kaudet[v['kausi']].add(v['vuoromerk'])

                if v['vuoromerk'] not in nopeudet[npk][v['kausi']].keys():
                    nopeudet[npk][v['kausi']][v['vuoromerk']] = set([])

                nopeudet[npk][v['kausi']][v['vuoromerk']].add(td)

                os = s


        self.render2('reitti_tiedot',vuorot=vuorot,reitti=reittidata,nopeudet=nopeudet,kaudet=kaudet,etaisyydet=etaisyydet)
