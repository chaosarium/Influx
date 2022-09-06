from django.contrib import admin
from .models import Question

# make Question table editable for damins
admin.site.register(Question)