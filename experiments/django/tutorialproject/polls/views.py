from django.shortcuts import render
import django as django
from django.http import HttpResponse, HttpResponseRedirect
from .models import Question, Choice
from django.template import loader
from django import http
from django.urls import reverse

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
    question = django.shortcuts.get_object_or_404(Question, pk=question_id)
    selected_choice = question.choice_set.get(pk=request.POST['choice'])
    try:
        selected_choice = question.choice_set.get(pk=request.POST['choice'])
    except (KeyError, Choice.DoesNotExist):
        # Redisplay the question voting form.
        return render(request, 'polls/detail.html', {
            'question': question,
            'error_message': "You didn't select a choice.",
        })
    else: 
        selected_choice.votes += 1
        selected_choice.save()
    return HttpResponseRedirect(reverse('polls:results', args=(question.id,)))

def results(request, question_id):
    question = django.shortcuts.get_object_or_404(Question, pk=question_id)
    return render(request, 'results.html', {'question': question})