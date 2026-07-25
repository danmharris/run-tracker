function loadMap(_e) {
  const container = document.querySelector('#map');
  if (container === null) return;

  const center = [container.dataset.centerLon, container.dataset.centerLat];
  const map = new maplibregl.Map({
        container: 'map',
        style: 'https://tiles.openfreemap.org/styles/bright',
        center: center,
        zoom: 15
    });

    map.on('load', () => {
        map.addSource('route', {
            'type': 'geojson',
            'data': document.location + '/geojson'
        });
        map.addLayer({
            'id': 'route',
            'type': 'line',
            'source': 'route',
            'layout': {
                'line-join': 'round',
                'line-cap': 'round'
            },
            'paint': {
                'line-color': '#888',
                'line-width': 8
            }
        });
    });
}

document.addEventListener('DOMContentLoaded', loadMap);
