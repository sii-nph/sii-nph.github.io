// 作品の拡大表示。JS が無効でも、サムネイルのリンクから本画像を開ける。
(function () {
  var dialog = document.getElementById('lightbox');
  var links = Array.prototype.slice.call(document.querySelectorAll('.tiles a'));
  if (!dialog || typeof dialog.showModal !== 'function' || links.length === 0) return;

  var img = dialog.querySelector('img');
  var caption = dialog.querySelector('figcaption');
  var current = 0;

  function show(index) {
    current = (index + links.length) % links.length;
    var link = links[current];
    img.src = link.href;
    img.alt = link.querySelector('img').alt;
    caption.textContent = [link.dataset.title, link.dataset.year, link.dataset.tools]
      .filter(Boolean)
      .join(' · ');
  }

  links.forEach(function (link, index) {
    link.addEventListener('click', function (event) {
      // 新しいタブで開く操作は、そのまま通す
      if (event.ctrlKey || event.metaKey || event.shiftKey || event.button !== 0) return;
      event.preventDefault();
      show(index);
      dialog.showModal();
    });
  });

  dialog.addEventListener('click', function (event) {
    var action = event.target.closest('button') && event.target.closest('button').dataset.action;
    if (action === 'prev') show(current - 1);
    else if (action === 'next') show(current + 1);
    else if (action === 'close' || !event.target.closest('img, figcaption')) dialog.close();
  });

  dialog.addEventListener('keydown', function (event) {
    if (event.key === 'ArrowLeft') show(current - 1);
    else if (event.key === 'ArrowRight') show(current + 1);
  });

  // 閉じたら画像を手放す（開くたびに読み込む）
  dialog.addEventListener('close', function () {
    img.removeAttribute('src');
  });

  if (links.length < 2) {
    dialog.querySelectorAll('[data-action="prev"], [data-action="next"]').forEach(function (button) {
      button.hidden = true;
    });
  }
})();
