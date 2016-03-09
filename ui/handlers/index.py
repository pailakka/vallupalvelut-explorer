from base import BaseHandler

class IndexHandler(BaseHandler):
    def get(self):
        curs = self.cursor


        self.render2('index',nakki='makkara')