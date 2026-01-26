# Django Standards

This document covers Django-specific coding standards and best practices.

## Models

### Model Naming

Use singular PascalCase for model names:

```python
# Good
class User(models.Model):
    pass

class BlogPost(models.Model):  # Singular, not BlogPosts
    pass

class OrderItem(models.Model):
    pass

# Bad
class Users(models.Model):  # Should be singular
    pass

class blog_post(models.Model):  # Should be PascalCase
    pass
```

### Model Field Definitions

```python
from django.db import models

class Article(models.Model):
    # Good: descriptive names, appropriate field types
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True, db_index=True)
    content = models.TextField()
    author = models.ForeignKey('User', on_delete=models.CASCADE, related_name='articles')
    published_at = models.DateTimeField(null=True, blank=True)
    is_featured = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-published_at']
        indexes = [
            models.Index(fields=['-published_at', 'is_featured']),
        ]
        verbose_name_plural = 'Articles'

    def __str__(self):
        return self.title

    def get_absolute_url(self):
        return reverse('article-detail', kwargs={'slug': self.slug})
```

### Model Methods

```python
class Order(models.Model):
    # ... fields ...

    # Good: business logic in model methods
    def calculate_total(self) -> Decimal:
        """Calculate order total including tax."""
        subtotal = sum(item.price * item.quantity for item in self.items.all())
        tax = subtotal * Decimal('0.1')
        return subtotal + tax

    def can_be_cancelled(self) -> bool:
        """Check if order can be cancelled."""
        return self.status in ['pending', 'confirmed']

    def cancel(self):
        """Cancel the order."""
        if not self.can_be_cancelled():
            raise ValueError("Order cannot be cancelled")
        self.status = 'cancelled'
        self.save()
```

## QuerySet Optimization

### Use select_related() for ForeignKey

```python
# Bad - N+1 query problem
articles = Article.objects.all()
for article in articles:
    print(article.author.name)  # Each iteration hits database

# Good - single query with JOIN
articles = Article.objects.select_related('author').all()
for article in articles:
    print(article.author.name)  # No additional queries
```

### Use prefetch_related() for ManyToMany

```python
# Bad - N+1 queries
articles = Article.objects.all()
for article in articles:
    for tag in article.tags.all():  # Query per article
        print(tag.name)

# Good - two queries total
articles = Article.objects.prefetch_related('tags').all()
for article in articles:
    for tag in article.tags.all():  # No additional queries
        print(tag.name)
```

### Custom Managers

```python
class PublishedManager(models.Manager):
    """Manager for published articles only."""
    def get_queryset(self):
        return super().get_queryset().filter(status='published')

class Article(models.Model):
    # ... fields ...
    status = models.CharField(max_length=20)

    objects = models.Manager()  # Default manager
    published = PublishedManager()  # Custom manager

# Usage
Article.published.all()  # Only published articles
Article.published.filter(author=user)  # Chainable
```

## Views

### Class-Based Views (Preferred)

```python
from django.views.generic import ListView, DetailView, CreateView
from django.contrib.auth.mixins import LoginRequiredMixin

# Good - class-based view
class ArticleListView(ListView):
    model = Article
    template_name = 'articles/list.html'
    context_object_name = 'articles'
    paginate_by = 20

    def get_queryset(self):
        return Article.published.select_related('author').order_by('-published_at')

class ArticleDetailView(DetailView):
    model = Article
    template_name = 'articles/detail.html'
    context_object_name = 'article'

    def get_queryset(self):
        return Article.published.select_related('author').prefetch_related('tags')

class ArticleCreateView(LoginRequiredMixin, CreateView):
    model = Article
    fields = ['title', 'content', 'tags']
    template_name = 'articles/create.html'

    def form_valid(self, form):
        form.instance.author = self.request.user
        return super().form_valid(form)
```

### Function-Based Views

```python
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.decorators import login_required

# Acceptable for simple views
@login_required
def article_list(request):
    articles = Article.published.select_related('author').order_by('-published_at')
    return render(request, 'articles/list.html', {'articles': articles})

@login_required
def article_vote(request, pk):
    """Simple action - function-based view is fine."""
    article = get_object_or_404(Article, pk=pk)
    article.votes.create(user=request.user)
    return redirect('article-detail', pk=article.pk)
```

## Forms

### Model Forms

```python
from django import forms
from .models import Article

class ArticleForm(forms.ModelForm):
    class Meta:
        model = Article
        fields = ['title', 'slug', 'content', 'tags']
        widgets = {
            'content': forms.Textarea(attrs={'rows': 10}),
            'tags': forms.CheckboxSelectMultiple(),
        }

    def clean_slug(self):
        """Validate slug is unique."""
        slug = self.cleaned_data['slug']
        if Article.objects.filter(slug=slug).exclude(pk=self.instance.pk).exists():
            raise forms.ValidationError("Slug must be unique")
        return slug

    def clean(self):
        """Cross-field validation."""
        cleaned_data = super().clean()
        title = cleaned_data.get('title')
        content = cleaned_data.get('content')

        if title and content and title.lower() in content.lower():
            raise forms.ValidationError("Title should not appear in content")

        return cleaned_data
```

## URL Configuration

### URL Naming

```python
# urls.py
from django.urls import path
from . import views

app_name = 'articles'

urlpatterns = [
    # Good: descriptive names, RESTful patterns
    path('', views.ArticleListView.as_view(), name='list'),
    path('<slug:slug>/', views.ArticleDetailView.as_view(), name='detail'),
    path('create/', views.ArticleCreateView.as_view(), name='create'),
    path('<int:pk>/edit/', views.ArticleUpdateView.as_view(), name='update'),
    path('<int:pk>/delete/', views.ArticleDeleteView.as_view(), name='delete'),
]

# Usage in templates
# {% url 'articles:list' %}
# {% url 'articles:detail' slug=article.slug %}
```

## Templates

### Template Organization

```
templates/
├── base.html
├── articles/
│   ├── list.html
│   ├── detail.html
│   ├── create.html
│   └── _article_card.html  # Partial template
└── components/
    ├── navbar.html
    └── footer.html
```

### Template Best Practices

```django
{# articles/detail.html #}
{% extends 'base.html' %}
{% load static %}

{% block title %}{{ article.title }}{% endblock %}

{% block content %}
<article>
    <h1>{{ article.title }}</h1>

    {# Good: auto-escaping enabled by default #}
    <div class="content">
        {{ article.content|linebreaks }}
    </div>

    {# Good: use safe only for trusted content #}
    <div class="html-content">
        {{ article.html_content|safe }}
    </div>

    {# Good: URL reversing #}
    <a href="{% url 'articles:list' %}">Back to list</a>

    {# Good: include partials #}
    {% include 'articles/_article_card.html' with article=related_article %}
</article>
{% endblock %}
```

## Signals

### Use Signals Sparingly

```python
from django.db.models.signals import post_save, pre_delete
from django.dispatch import receiver

# Good: appropriate use - sending notification
@receiver(post_save, sender=Order)
def order_created_notification(sender, instance, created, **kwargs):
    """Send notification when order is created."""
    if created:
        send_order_confirmation_email(instance)

# Bad: business logic should be in model/view
@receiver(post_save, sender=Article)
def update_article_count(sender, instance, **kwargs):
    # This should be in a model method or view
    instance.author.article_count += 1
    instance.author.save()
```

## Admin

### Admin Configuration

```python
from django.contrib import admin
from .models import Article, Comment

@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    list_display = ['title', 'author', 'status', 'published_at', 'is_featured']
    list_filter = ['status', 'is_featured', 'published_at']
    search_fields = ['title', 'content', 'author__username']
    prepopulated_fields = {'slug': ('title',)}
    date_hierarchy = 'published_at'
    ordering = ['-published_at']

    fieldsets = (
        ('Content', {
            'fields': ('title', 'slug', 'content', 'author')
        }),
        ('Metadata', {
            'fields': ('status', 'is_featured', 'published_at', 'tags')
        }),
    )

    def get_queryset(self, request):
        """Optimize admin queryset."""
        return super().get_queryset(request).select_related('author')

class CommentInline(admin.TabularInline):
    model = Comment
    extra = 0
    readonly_fields = ['created_at']
```

## Testing

### Test Structure

```python
from django.test import TestCase, Client
from django.urls import reverse
from .models import Article, User

class ArticleModelTest(TestCase):
    def setUp(self):
        """Create test data."""
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123'
        )
        self.article = Article.objects.create(
            title='Test Article',
            content='Test content',
            author=self.user
        )

    def test_article_creation(self):
        """Test article is created correctly."""
        self.assertEqual(self.article.title, 'Test Article')
        self.assertEqual(self.article.author, self.user)

    def test_article_str(self):
        """Test string representation."""
        self.assertEqual(str(self.article), 'Test Article')

class ArticleViewTest(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = User.objects.create_user(
            username='testuser',
            password='testpass123'
        )
        self.article = Article.objects.create(
            title='Test Article',
            author=self.user,
            status='published'
        )

    def test_article_list_view(self):
        """Test article list displays correctly."""
        response = self.client.get(reverse('articles:list'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Test Article')

    def test_article_create_requires_login(self):
        """Test create view requires authentication."""
        response = self.client.get(reverse('articles:create'))
        self.assertEqual(response.status_code, 302)  # Redirect to login

    def test_article_create_authenticated(self):
        """Test authenticated user can create article."""
        self.client.login(username='testuser', password='testpass123')
        response = self.client.post(reverse('articles:create'), {
            'title': 'New Article',
            'content': 'New content',
        })
        self.assertEqual(response.status_code, 302)  # Redirect after success
        self.assertTrue(Article.objects.filter(title='New Article').exists())
```

### Factory Pattern

```python
# tests/factories.py
import factory
from .models import User, Article

class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User

    username = factory.Sequence(lambda n: f'user{n}')
    email = factory.LazyAttribute(lambda obj: f'{obj.username}@example.com')

class ArticleFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Article

    title = factory.Sequence(lambda n: f'Article {n}')
    content = factory.Faker('paragraph')
    author = factory.SubFactory(UserFactory)
    status = 'published'

# Usage in tests
def test_article_list():
    ArticleFactory.create_batch(5)  # Create 5 articles
    response = client.get(reverse('articles:list'))
    assert response.status_code == 200
```

## Security

### CSRF Protection

```python
# Keep CSRF protection enabled (default)
# settings.py
CSRF_COOKIE_SECURE = True  # HTTPS only
CSRF_COOKIE_HTTPONLY = True

# In views - CSRF token is automatic for forms
# Only use csrf_exempt for specific API endpoints with alternative auth
from django.views.decorators.csrf import csrf_exempt

# Bad - disabling CSRF globally
# Good - only exempt specific API views with token auth
@csrf_exempt  # Only if using token authentication
def api_endpoint(request):
    pass
```

### XSS Prevention

```django
{# Django templates auto-escape by default - this is safe #}
<p>{{ user_input }}</p>

{# Only use |safe for trusted content #}
<div>{{ trusted_html|safe }}</div>

{# Use |escape explicitly if needed #}
<script>
var data = "{{ user_input|escapejs }}";
</script>
```

### SQL Injection Prevention

```python
# Good - Django ORM prevents SQL injection automatically
User.objects.filter(username=user_input)

# Good - raw queries with parameters
User.objects.raw("SELECT * FROM users WHERE username = %s", [user_input])

# Bad - string formatting
User.objects.raw(f"SELECT * FROM users WHERE username = '{user_input}'")  # NEVER!
```

### Production Settings

```python
# settings/production.py
DEBUG = False
ALLOWED_HOSTS = ['yourdomain.com']

# Security settings
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
```

## App Structure

### Django App Organization

```
myapp/
├── __init__.py
├── admin.py           # Admin configuration
├── apps.py            # App configuration
├── models.py          # Database models
├── views.py           # Views
├── urls.py            # URL routing
├── forms.py           # Forms
├── managers.py        # Custom managers
├── signals.py         # Signal handlers
├── tasks.py           # Celery tasks (if using)
├── migrations/        # Database migrations
│   └── __init__.py
├── templates/         # App-specific templates
│   └── myapp/
│       └── list.html
└── tests/             # Tests
    ├── __init__.py
    ├── test_models.py
    ├── test_views.py
    └── factories.py
```

## References

- [Django Documentation](https://docs.djangoproject.com/)
- [Django Best Practices](https://django-best-practices.readthedocs.io/)
- [Two Scoops of Django](https://www.feldroy.com/books/two-scoops-of-django-3-x)
