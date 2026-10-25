// 作品一覧のスクロール演出。画面の中央に近い作品ほど大きく、遠いほど小さく表示する。
// 画面の右側には、中央にある作品の情報（制作年・使用ツール）を表示する。
// JS が使えない、または「動きを減らす」設定のときは何もしない（全作品が通常の大きさで並ぶ）。
(function () {
  var feed = document.querySelector('.feed');
  if (!feed) return;
  if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  // 調整用の定数
  var MIN_SCALE = 0.55;    // 中央から最も遠い作品の倍率
  var MIN_OPACITY = 0.55;  // 同じく不透明度
  var RANGE_VIEWPORT = 0.6; // 倍率が変わる距離（画面の高さに対する割合）
  var RANGE_IMAGE = 1.0;    // 同じく上限（最も高い絵の高さに対する割合）。隣の絵と重ならないための値
  var GAP_VIEWPORT = 0.10;  // 中央の絵と隣の絵の見た目の間隔（画面の高さに対する割合）
  var GAP_MIN = 48;         // 同じく下限（px）
  var GAP_MAX = 120;        // 同じく上限（px）

  var items = Array.prototype.slice.call(feed.querySelectorAll('.feed-item'));
  var info = document.querySelector('.feed-info');
  var yearEl = info && info.querySelector('.feed-year');
  var titleEl = info && info.querySelector('.feed-title');
  var toolsEl = info && info.querySelector('.feed-tools');

  var centers = [];  // 各作品の中心（ページ先頭からの距離）
  var maxHeight = 0; // 最も高い絵の高さ
  var active = -1;
  var ticking = false;

  function scrollTop() {
    return window.pageYOffset || document.documentElement.scrollTop;
  }

  // 絵と絵の間隔と、各作品の位置を決める。読み込み時と画面サイズが変わったときだけ行う
  // （作品の高さは CSS で決まり、拡大縮小では変わらない）
  function measure() {
    var gap = Math.max(GAP_MIN, Math.min(GAP_MAX, window.innerHeight * GAP_VIEWPORT));
    var heights = items.map(function (item) {
      return item.getBoundingClientRect().height;
    });
    maxHeight = Math.max.apply(null, heights);

    // 中央の絵が 1.0、隣が MIN_SCALE のとき、縮んだ隣は上下に「高さ × shrink」ずつ空白を作る。
    // その分を差し引いて、絵の向きに関係なく、中央の絵と隣の絵の見た目の間隔が約 gap になるようにする（負の値になることもある）
    var shrink = (1 - MIN_SCALE) / 2;
    items.forEach(function (item, index) {
      if (index === 0) return;
      var average = (heights[index - 1] + heights[index]) / 2;
      item.style.setProperty('--gap', (gap - shrink * average).toFixed(1) + 'px');
    });

    // 間隔を入れたあとの位置を測る
    var top = scrollTop();
    centers = items.map(function (item) {
      var rect = item.getBoundingClientRect();
      return rect.top + top + rect.height / 2;
    });
  }

  function smooth(t) {
    return t * t * (3 - 2 * t);
  }

  function setActive(index) {
    if (index === active) return;
    active = index;
    if (!info) return;
    var link = items[index].querySelector('a');
    yearEl.textContent = link.dataset.year || '';
    titleEl.textContent = link.dataset.title || '';
    toolsEl.textContent = link.dataset.tools || '';
  }

  function update() {
    ticking = false;
    var viewport = window.innerHeight;
    var middle = scrollTop() + viewport / 2;
    var range = Math.min(viewport * RANGE_VIEWPORT, maxHeight * RANGE_IMAGE);
    var nearest = 0;
    var nearestDistance = Infinity;

    items.forEach(function (item, index) {
      var distance = Math.abs(centers[index] - middle);
      var t = smooth(Math.max(0, 1 - distance / range));
      item.style.setProperty('--s', (MIN_SCALE + (1 - MIN_SCALE) * t).toFixed(3));
      item.style.setProperty('--o', (MIN_OPACITY + (1 - MIN_OPACITY) * t).toFixed(3));
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = index;
      }
    });

    // 最初の作品より上、または最後の作品より下では、右側の情報を、絵の縮小に合わせて薄くする
    // （パネルは列の下端まで固定されるため、絵が縮んでも大きく残って見えるのを防ぐ）
    if (info) {
      var beyond = Math.max(centers[0] - middle, middle - centers[centers.length - 1], 0);
      info.style.opacity = smooth(Math.max(0, 1 - beyond / range)).toFixed(3);
    }

    setActive(nearest);
  }

  function requestUpdate() {
    if (ticking) return;
    ticking = true;
    window.requestAnimationFrame(update);
  }

  function remeasure() {
    measure();
    requestUpdate();
  }

  feed.classList.add('is-live');
  if (info) info.hidden = false;
  measure();
  update();

  window.addEventListener('scroll', requestUpdate, { passive: true });
  window.addEventListener('resize', remeasure);
  window.addEventListener('load', remeasure);
})();
