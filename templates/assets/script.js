(function(document) {

    // Simple table filtering
    var LightTableFilter = (function(Arr) {

        var _input;

        function _onInputEvent(e) {
            _input = e.target;
            var table = document.getElementById(_input.getAttribute('data-table'));
            Arr.forEach.call(table.tBodies, function(tbody) {
                Arr.forEach.call(tbody.rows, _filter);
            });
        }

        function _filter(row) {
            var text = row.textContent.toLowerCase(), val = _input.value.toLowerCase();
            row.style.display = text.indexOf(val) === -1 ? 'none' : 'table-row';
        }

        return {
            init: function() {
                var inputs = document.getElementsByClassName('table-filter-input');
                Arr.forEach.call(inputs, function(input) {
                    input.oninput = _onInputEvent;
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
