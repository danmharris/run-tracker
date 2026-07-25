function loadMap(_e) {
  const container = document.querySelector('#map');
  if (container === null) return;

  const { geojsonUrl, minLon, minLat, maxLon, maxLat } = container.dataset;
  const map = new maplibregl.Map({
        container: 'map',
        style: 'https://tiles.openfreemap.org/styles/bright',
        bounds: [
          [minLon, minLat],
          [maxLon, maxLat]
        ]
    });

    map.on('load', () => {
        map.addSource('route', {
            'type': 'geojson',
            'data': geojsonUrl
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
