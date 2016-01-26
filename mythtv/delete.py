#!/usr/bin/env python
from MythTV import MythDB
from datetime import datetime, timedelta

MAXAGE=365 # number of days

db = MythDB()
recs = db.searchRecorded(custom=(('starttime<%s', datetime.now()-timedelta(MAXAGE)),))
if recs is None:
    print 'No old recordings to delete'
else:
    for rec in recs:
        if rec.subtitle:
            print 'Deleting "%s: %s - %s"' % (rec.endtime, rec.title, rec.subtitle)
        else:
            print 'Deleting %s: "%s"' % (rec.endtime, rec.title)
        rec.delete()


