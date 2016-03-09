from base import BaseHandler
import json
import pprint
import string



def handleStationQuery(curs,execparams,kuntanumerot):
    curs.execute(*execparams)
    pysakit_raw = curs.fetchall()
    pysakit = {}

    for pr in pysakit_raw:
        pysakit[pr['gid']] = pr
        #pysakit[pr['gid']]['has_interpolated'] = pysakit[pr['stationid']]['has_interpolated'] or pr['has_interpolated']

    return pysakit

class IndexHandler(BaseHandler):
    def get(self):
        pysakkiquery = self.get_argument('q','')
        pysakit = {}
        if len(pysakkiquery) > 0:
            if pysakkiquery.isdigit() or (pysakkiquery.upper().startswith('V') and pysakkiquery[1:].isdigit()):
                if (pysakkiquery.upper().startswith('V') and pysakkiquery[1:].isdigit()):
                    execparams = ('SELECT * FROM pysakit WHERE gid::varchar ILIKE %s',(pysakkiquery[1:] + '%',))
                else:
                    execparams = ('SELECT * FROM pysakit WHERE valtakid::varchar ILIKE %s',(pysakkiquery + '%',))
            else:
                #execparams = ('SELECT *,similarity(nimi,%s) FROM pysakit WHERE nimi %% %s ORDER BY nimi <-> %s ASC',(pysakkiquery,pysakkiquery,pysakkiquery))
                pysakkiquery = pysakkiquery.lower()
                pysakkiquery = pysakkiquery.replace(' las',' las linja-autoasema')
                pysakkiquery = pysakkiquery.replace(' mh',' mh matkahuolto')
                execparams = ('SELECT *,similarity(nimi,%s) FROM pysakit WHERE nimi %% %s ORDER BY similarity(nimi,%s) ASC',(pysakkiquery,pysakkiquery,pysakkiquery))

            curs = self.cursor
            pysakit = handleStationQuery(curs,execparams,self.application.kuntanumerot)

        #self.write(pprint.pformat(curs.mogrify(*execparams)))
        if self.get_argument('format','tpl') == 'json':
            pyssort = [p[1] for p in sorted([(p['similarity'] if 'similarity' in p else p['nimi'],p) for p in pysakit.values()],reverse=True)]
            self.write(json.dumps(pyssort, indent=4, sort_keys=True))
        else:
            self.render2('pysakit_index',pysakit=pysakit.values())


class NearHandler(BaseHandler):
    def get(self):
        stationid = self.get_argument('s',None)
        distance = int(self.get_argument('d',None))
        assert stationid,'Station must be defined'

        execparams = ('SELECT s1.*,(s1.x-s2.x)*(s1.x-s2.x)+(s1.y-s2.y)*(s1.y-s2.y) as dist FROM pysakit s1 LEFT JOIN pysakit s2 ON s2.gid=%s WHERE s1.x-%s <= s1.x and s1.y-%s <= s1.y and s1.x+%s >= s2.x and s1.y+%s >= s2.y and (s1.x-s2.x)*(s1.x-s2.x)+(s1.y-s2.y)*(s1.y-s2.y) < %s ORDER BY dist ASC',(stationid,distance,distance,distance,distance,distance**2))
        curs = self.cursor

        #self.write(curs.mogrify(*execparams))
        #return
        pysakit = handleStationQuery(curs,execparams,self.application.kuntanumerot)
        if pysakit.has_key(stationid):
            del pysakit[stationid]
        if self.get_argument('format','tpl') == 'json':
            self.write(json.dumps(pysakit.values(), indent=4, sort_keys=True))
        else:
            self.render2('pysakit_index',pysakit=pysakit.values())
