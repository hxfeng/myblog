<div class="copyright" >
  {% set current = date(Date.now(), "YYYY") %}
  &copy; {% if theme.since and theme.since != current %} {{ theme.since }} - {% endif %}
  <span itemprop="copyrightYear">{{ current }}</span>
  <span class="with-love">
    <i class="fa fa-{{ theme.authoricon }}"></i>
  </span>
  <span class="author" itemprop="copyrightHolder">{{ config.author }}</span>
</div>

{% if theme.copyright %}
<div class="powered-by">
  {{ __('footer.powered', '<a class="theme-link" href="https://hxfeng.github.io/blog">hxfeng</a>') }}
</div>

<div class="theme-info">
 <!-- {{ __('footer.theme') }} - -->
  <a class="theme-link" href="https://hxfeng.github.io">
   <!-- NexT.{{ theme.scheme }} -->
   我的博客
  </a>
</div>
{% endif %}
