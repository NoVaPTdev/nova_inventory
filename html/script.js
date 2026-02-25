var grid = document.getElementById('inv-grid');
var invEl = document.getElementById('inventory');
var tooltip = document.getElementById('tooltip');
var slots = {};
var maxSlots = 40;
var maxWeight = 120000;
var currentWeight = 0;
var activeSlot = null;

// Custom drag state
var isDragging = false;
var dragFromSlot = null;
var dragGhost = null;
var dragStartX = 0;
var dragStartY = 0;
var dragThreshold = 5;

function nuiCallback(name, data, cb) {
    fetch('https://nova_inventory/' + name, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    }).then(function (r) { return r.json(); }).then(function (r) { if (cb) cb(r); });
}

function renderGrid() {
    grid.innerHTML = '';
    for (var i = 1; i <= maxSlots; i++) {
        var slot = document.createElement('div');
        slot.className = 'inv-slot';
        slot.dataset.slot = i;
        if (i <= 5) {
            slot.classList.add('hotbar');
            slot.dataset.hotbar = i;
        }

        var item = slots[i];
        if (item && item.name) {
            slot.innerHTML =
                '<div class="slot-content">' +
                    '<div class="slot-icon">' + getIcon(item.name) + '</div>' +
                    '<div class="slot-label">' + (item.label || item.name) + '</div>' +
                '</div>' +
                (item.amount > 1 ? '<span class="slot-amount">' + item.amount + '</span>' : '') +
                '<span class="slot-weight">' + ((item.weight || 0) * (item.amount || 1) / 1000).toFixed(1) + 'kg</span>';
        }

        slot.addEventListener('mousedown', onMouseDown);
        slot.addEventListener('dblclick', onSlotDblClick);

        grid.appendChild(slot);
    }
    updateWeight();
}

function getIcon(name) {
    var icons = {
        'bread': '🍞', 'water': '💧', 'burger': '🍔', 'bandage': '🩹',
        'phone': '📱', 'lockpick': '🔧', 'weapon_pistol': '🔫',
        'sandwich': '🥪', 'coffee': '☕', 'energy_drink': '⚡',
        'medikit': '🏥', 'radio': '📻', 'repairkit': '🔩',
        'jerrycan': '⛽', 'armor': '🛡️', 'id_card': '🪪',
        'driver_license': '🪪', 'weapon_license': '🪪',
    };
    return icons[name] || '📦';
}

function updateWeight() {
    var pct = maxWeight > 0 ? (currentWeight / maxWeight) * 100 : 0;
    document.getElementById('weight-fill').style.width = Math.min(pct, 100) + '%';
    document.getElementById('weight-text').textContent =
        (currentWeight / 1000).toFixed(1) + ' / ' + (maxWeight / 1000).toFixed(1) + ' kg';

    if (pct > 90) {
        document.getElementById('weight-fill').style.background = 'linear-gradient(90deg, #ef4444, #f59e0b)';
    } else {
        document.getElementById('weight-fill').style.background = 'linear-gradient(90deg, #84cc16, #a3e635)';
    }
}

// ============================================================
// CUSTOM DRAG & DROP (mouse-based, works in FiveM CEF)
// ============================================================

function onMouseDown(e) {
    if (e.button !== 0) return;
    var slotEl = e.currentTarget;
    var slotIdx = parseInt(slotEl.dataset.slot);
    var item = slots[slotIdx];
    if (!item || !item.name) return;

    dragFromSlot = slotIdx;
    dragStartX = e.clientX;
    dragStartY = e.clientY;
    isDragging = false;

    e.preventDefault();
}

document.addEventListener('mousemove', function(e) {
    if (dragFromSlot === null) return;

    var dx = e.clientX - dragStartX;
    var dy = e.clientY - dragStartY;

    if (!isDragging && (Math.abs(dx) > dragThreshold || Math.abs(dy) > dragThreshold)) {
        isDragging = true;
        hideTooltip();
        createDragGhost(dragFromSlot, e.clientX, e.clientY);

        var fromEl = grid.querySelector('[data-slot="' + dragFromSlot + '"]');
        if (fromEl) fromEl.classList.add('dragging');
    }

    if (isDragging && dragGhost) {
        dragGhost.style.left = (e.clientX - 40) + 'px';
        dragGhost.style.top = (e.clientY - 40) + 'px';

        clearHighlights();
        var target = getSlotUnderMouse(e.clientX, e.clientY);
        if (target && parseInt(target.dataset.slot) !== dragFromSlot) {
            target.classList.add('drag-over');
        }
    }
});

document.addEventListener('mouseup', function(e) {
    if (dragFromSlot === null) return;

    if (isDragging) {
        var target = getSlotUnderMouse(e.clientX, e.clientY);
        if (target) {
            var toSlot = parseInt(target.dataset.slot);
            if (toSlot && dragFromSlot !== toSlot) {
                nuiCallback('moveItem', { fromSlot: dragFromSlot, toSlot: toSlot });
            }
        }
        removeDragGhost();
        clearHighlights();

        var fromEl = grid.querySelector('[data-slot="' + dragFromSlot + '"]');
        if (fromEl) fromEl.classList.remove('dragging');
    } else if (dragFromSlot !== null) {
        onSlotClick(dragFromSlot);
    }

    dragFromSlot = null;
    isDragging = false;
});

function createDragGhost(slotIdx, x, y) {
    removeDragGhost();
    var item = slots[slotIdx];
    if (!item) return;

    dragGhost = document.createElement('div');
    dragGhost.className = 'drag-ghost';
    dragGhost.innerHTML =
        '<div class="slot-icon">' + getIcon(item.name) + '</div>' +
        '<div class="slot-label">' + (item.label || item.name) + '</div>';
    dragGhost.style.left = (x - 40) + 'px';
    dragGhost.style.top = (y - 40) + 'px';
    document.body.appendChild(dragGhost);
}

function removeDragGhost() {
    if (dragGhost) {
        dragGhost.remove();
        dragGhost = null;
    }
}

function getSlotUnderMouse(x, y) {
    var allSlots = grid.querySelectorAll('.inv-slot');
    for (var i = 0; i < allSlots.length; i++) {
        var rect = allSlots[i].getBoundingClientRect();
        if (x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom) {
            return allSlots[i];
        }
    }
    return null;
}

function clearHighlights() {
    var els = grid.querySelectorAll('.drag-over');
    for (var i = 0; i < els.length; i++) {
        els[i].classList.remove('drag-over');
    }
}

// ============================================================
// CLICK (triggered from mouseup when no drag occurred)
// ============================================================

function onSlotClick(slotIdx) {
    var item = slots[slotIdx];
    if (!item || !item.name) { hideTooltip(); return; }

    activeSlot = slotIdx;
    var slotEl = grid.querySelector('[data-slot="' + slotIdx + '"]');
    if (!slotEl) return;

    var rect = slotEl.getBoundingClientRect();
    document.getElementById('tooltip-name').textContent = item.label || item.name;
    document.getElementById('tooltip-desc').textContent = item.metadata && item.metadata.description ? item.metadata.description : (item.type || 'Item');
    document.getElementById('tooltip-weight').textContent = 'Peso: ' + ((item.weight || 0) / 1000).toFixed(1) + ' kg cada';
    tooltip.style.display = 'block';
    tooltip.style.left = (rect.right + 10) + 'px';
    tooltip.style.top = rect.top + 'px';
}

function onSlotDblClick(e) {
    var slotEl = e.currentTarget;
    var slotIdx = parseInt(slotEl.dataset.slot);
    if (slots[slotIdx]) {
        nuiCallback('useItem', { slot: slotIdx });
        hideTooltip();
    }
}

function hideTooltip() {
    tooltip.style.display = 'none';
    activeSlot = null;
}

// Botões do tooltip
document.getElementById('btn-use').addEventListener('click', function () {
    if (activeSlot) nuiCallback('useItem', { slot: activeSlot });
    hideTooltip();
});
document.getElementById('btn-drop').addEventListener('click', function () {
    if (activeSlot) nuiCallback('dropItem', { slot: activeSlot, amount: 1 });
    hideTooltip();
});

// Fechar com ESC ou clique fora
document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' || e.key === 'Tab') {
        nuiCallback('close');
    }
});
document.getElementById('inventory').addEventListener('click', function (e) {
    if (e.target === invEl && !isDragging) nuiCallback('close');
});

// NUI Messages
window.addEventListener('message', function (e) {
    var d = e.data;
    if (d.action === 'open') {
        invEl.style.display = 'flex';
        hideTooltip();
    }
    if (d.action === 'close') {
        invEl.style.display = 'none';
        hideTooltip();
        removeDragGhost();
        dragFromSlot = null;
        isDragging = false;
    }
    if (d.action === 'updateInventory') {
        var rawSlots = d.slots || {};
        slots = {};
        if (Array.isArray(rawSlots)) {
            for (var i = 0; i < rawSlots.length; i++) {
                if (rawSlots[i]) slots[i + 1] = rawSlots[i];
            }
        } else {
            for (var key in rawSlots) {
                if (rawSlots.hasOwnProperty(key)) {
                    slots[parseInt(key)] = rawSlots[key];
                }
            }
        }
        maxWeight = d.maxWeight || 120000;
        currentWeight = d.currentWeight || 0;
        renderGrid();
    }
});

// Inicializar grid vazia
renderGrid();
