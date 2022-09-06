from django.shortcuts import render
import django as django
from django.http import HttpResponse
from .models import Question
from django.template import loader
from django import http

def index(request):
    latest_question_list = Question.objects.order_by('-pub_date')[:5]

    context = {
        'latest_question_list': latest_question_list,
    }
    
    return render(request, 'index.html', context)

    # longer way
    # template = loader.get_template('index.html')
    # return HttpResponse(template.render(context, request))

def detail(request, question_id):
    question = django.shortcuts.get_object_or_404(Question, pk=question_id)
    
    # longer way
    # try:
    #     question = Question.objects.get(pk=question_id)
    # except Question.DoesNotExist:
    #     raise http.Http404("Question does not exist")
    
    return render(request, "detail.html", {'question': question})

def results(request, question_id):
    response = f"You're looking at the results of question {question_id}."
    return HttpResponse(response)

def vote(request, question_id):
    return HttpResponse(f"You're voting on question {question_id}.")