// ============================================
// D3.js Triangulation Flow Diagram
// (Simplified Sankey-like flow)
// ============================================
import { triangulationData } from '../data.js';

export function renderTriangulation(containerId) {
  const container = document.getElementById(containerId);
  if (!container) return;

  container.innerHTML = '';

  const width = container.clientWidth;
  const height = 400;

  const svg = d3.select(`#${containerId}`)
    .append('svg')
    .attr('viewBox', `0 0 ${width} ${height}`)
    .attr('preserveAspectRatio', 'xMidYMid meet')
    .attr('role', 'img')
    .attr('aria-label', 'Three-way data triangulation flow: Tiko Platform, Facility Registers, and DHIS2 converging into verified data');

  const nodes = triangulationData.nodes;
  const sourceColors = {
    digital: '#66C2A5',
    hmis: '#FC8D62',
    dhis2: '#8DA0CB',
    verify: '#1a365d',
    output: '#1B9E77'
  };

  // Position nodes
  const positions = {
    tiko:   { x: width * 0.12, y: height * 0.2 },
    hmis:   { x: width * 0.12, y: height * 0.5 },
    dhis2:  { x: width * 0.12, y: height * 0.8 },
    verify: { x: width * 0.55, y: height * 0.5 },
    output: { x: width * 0.88, y: height * 0.5 }
  };

  const nodeW = 140;
  const nodeH = 55;

  // Draw flow paths
  const sources = ['tiko', 'hmis', 'dhis2'];
  sources.forEach((src, i) => {
    const from = positions[src];
    const to = positions.verify;

    const path = d3.path();
    path.moveTo(from.x + nodeW / 2, from.y);
    path.bezierCurveTo(
      from.x + nodeW / 2 + (to.x - from.x) * 0.4, from.y,
      to.x - nodeW / 2 - (to.x - from.x) * 0.3, to.y,
      to.x - nodeW / 2, to.y
    );

    svg.append('path')
      .attr('d', path.toString())
      .attr('fill', 'none')
      .attr('stroke', sourceColors[src])
      .attr('stroke-width', 3)
      .attr('opacity', 0.5)
      .attr('stroke-dasharray', function() { return this.getTotalLength(); })
      .attr('stroke-dashoffset', function() { return this.getTotalLength(); })
      .transition()
      .duration(1500)
      .delay(i * 200)
      .attr('stroke-dashoffset', 0);

    // Animated dots along path
    const pathEl = svg.append('path')
      .attr('d', path.toString())
      .attr('fill', 'none')
      .attr('stroke', 'none')
      .node();

    for (let j = 0; j < 3; j++) {
      svg.append('circle')
        .attr('r', 4)
        .attr('fill', sourceColors[src])
        .attr('opacity', 0)
        .transition()
        .delay(i * 200 + 1500 + j * 600)
        .duration(0)
        .attr('opacity', 0.8)
        .transition()
        .duration(2000)
        .ease(d3.easeLinear)
        .attrTween('transform', function() {
          return function(t) {
            const p = pathEl.getPointAtLength(t * pathEl.getTotalLength());
            return `translate(${p.x},${p.y})`;
          };
        })
        .attr('opacity', 0)
        .on('end', function repeat() {
          d3.select(this)
            .attr('opacity', 0.8)
            .transition()
            .duration(2000)
            .ease(d3.easeLinear)
            .attrTween('transform', function() {
              return function(t) {
                const p = pathEl.getPointAtLength(t * pathEl.getTotalLength());
                return `translate(${p.x},${p.y})`;
              };
            })
            .attr('opacity', 0)
            .on('end', repeat);
        });
    }
  });

  // Verify to output path
  const vFrom = positions.verify;
  const vTo = positions.output;
  const vPath = d3.path();
  vPath.moveTo(vFrom.x + nodeW / 2, vFrom.y);
  vPath.bezierCurveTo(
    vFrom.x + nodeW / 2 + 60, vFrom.y,
    vTo.x - nodeW / 2 - 60, vTo.y,
    vTo.x - nodeW / 2, vTo.y
  );

  svg.append('path')
    .attr('d', vPath.toString())
    .attr('fill', 'none')
    .attr('stroke', '#1B9E77')
    .attr('stroke-width', 5)
    .attr('opacity', 0.5)
    .attr('stroke-dasharray', function() { return this.getTotalLength(); })
    .attr('stroke-dashoffset', function() { return this.getTotalLength(); })
    .transition()
    .duration(1200)
    .delay(1000)
    .attr('stroke-dashoffset', 0);

  // Draw nodes
  nodes.forEach(node => {
    const pos = positions[node.id];
    const g = svg.append('g')
      .attr('transform', `translate(${pos.x - nodeW / 2},${pos.y - nodeH / 2})`);

    g.append('rect')
      .attr('width', nodeW)
      .attr('height', nodeH)
      .attr('fill', '#fff')
      .attr('stroke', sourceColors[node.id])
      .attr('stroke-width', 2.5)
      .attr('rx', 10)
      .attr('filter', 'drop-shadow(0 2px 4px rgba(0,0,0,0.1))');

    g.append('text')
      .attr('x', nodeW / 2)
      .attr('y', nodeH / 2 - 6)
      .attr('text-anchor', 'middle')
      .attr('font-size', '12px')
      .attr('font-weight', '700')
      .attr('fill', '#1a202c')
      .text(node.name);

    g.append('text')
      .attr('x', nodeW / 2)
      .attr('y', nodeH / 2 + 10)
      .attr('text-anchor', 'middle')
      .attr('font-size', '9px')
      .attr('fill', '#718096')
      .text(node.desc.length > 35 ? node.desc.substring(0, 35) + '...' : node.desc);
  });

  // Arrow marker
  svg.append('defs').append('marker')
    .attr('id', 'arrow')
    .attr('viewBox', '0 0 10 10')
    .attr('refX', 8).attr('refY', 5)
    .attr('markerWidth', 6).attr('markerHeight', 6)
    .attr('orient', 'auto')
    .append('path')
    .attr('d', 'M0,0 L10,5 L0,10 Z')
    .attr('fill', '#1B9E77');
}
