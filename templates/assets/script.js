(function(document) {

    // Simple table filtering
    var LightTableFilter = (function(Arr) {

        var _input, _link, _reset;

        function _onInputEvent(e) {
            _input = e.target;
            var table = document.getElementById(_input.getAttribute('data-table'));
            Arr.forEach.call(table.tBodies, function(tbody) {
                Arr.forEach.call(tbody.rows, _filterName);
            });
            _reset.style.display = _input.value != '' ? "block" : "none";
        }

        function _onClickEvent(e) {
            _link = e.target;
            var table = document.getElementById(document.getElementsByClassName('table-filter-input')[0].getAttribute('data-table'));
            Arr.forEach.call(table.tBodies, function(tbody) {
                Arr.forEach.call(tbody.rows, _filterStatus);
            });

            _reset.style.display = _link != _reset ? "block" : "none";
            if(_input){
                _input.value = "";
            }

            return false;
        }

        function _filterName(row) {
            var text = row.getElementsByClassName('pkg')[0].textContent.toLowerCase(),
                val = _input.value.toLowerCase();
            row.style.display = text.indexOf(val) === -1 ? 'none' : 'table-row';
        }

        function _filterStatus(row) {
            var text = row.textContent.toLowerCase(),
                val = _link.dataset.status.toLowerCase();
            row.style.display = text.indexOf(val) === -1 ? 'none' : 'table-row';
        }

        return {
            init: function() {
                _reset = document.getElementsByClassName('reset-filter')[0];

                var inputs = document.getElementsByClassName('table-filter-input');
                Arr.forEach.call(inputs, function(input) {
                    input.oninput = _onInputEvent;
                });

                var links = document.getElementsByClassName('filter-status');
                Arr.forEach.call(links, function(link) {
                    link.onclick = _onClickEvent;
                });
            }
        };
    })(Array.prototype);


    document.addEventListener('readystatechange', function() {
        if (document.readyState === 'complete') {
            LightTableFilter.init();

            // Panel content toggling
            Array.prototype.forEach.call(document.getElementsByClassName('panel-heading'), function(heading){
                heading.onclick = function(e){
                    var body = e.target.parentNode.getElementsByClassName('panel-body')[0];
                    if(body.classList.contains('panel-body')){
                        body.classList.toggle('panel-hidden')
                    }
                }
            });
        }
    });

})(document);
