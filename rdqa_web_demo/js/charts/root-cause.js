// ============================================
// D3.js Donut Chart — Root Cause Analysis
// ============================================
import { rootCauses } from '../data.js';

export function renderRootCauseChart(containerId) {
  const container = document.getElementById(containerId);
  if (!container) return;

  container.innerHTML = '';

  const size = Math.min(container.clientWidth, 400);
  const radius = size / 2;
  const innerRadius = radius * 0.55;

  const svg = d3.select(`#${containerId}`)
    .append('svg')
    .attr('viewBox', `0 0 ${size} ${size}`)
    .attr('preserveAspectRatio', 'xMidYMid meet')
    .attr('role', 'img')
    .attr('aria-label', 'Root cause analysis breakdown donut chart')
    .append('g')
    .attr('transform', `translate(${size / 2},${size / 2})`);

  // Defs for patterns
  const defs = svg.append('defs');
  const patterns = [
    { id: 'pat-human', d: 'M0,3 L6,3', color: '#E78AC3' },
    { id: 'pat-system', d: 'M0,0 L6,6 M0,6 L6,0', color: '#A6D854' },
    { id: 'pat-supply', d: 'M3,0 L3,6', color: '#FFD92F' },
    { id: 'pat-intent', d: 'M0,6 L6,0', color: '#E5C494' },
    { id: 'pat-context', d: 'M0,3 L6,3 M3,0 L3,6', color: '#B3B3B3' }
  ];

  patterns.forEach(p => {
    defs.append('pattern')
      .attr('id', p.id)
      .attr('patternUnits', 'userSpaceOnUse')
      .attr('width', 6).attr('height', 6)
      .append('path')
      .attr('d', p.d)
      .attr('stroke', p.color)
      .attr('stroke-width', 1);
  });

  const pie = d3.pie()
    .value(d => d.percentage)
    .sort(null)
    .padAngle(0.02);

  const arc = d3.arc()
    .innerRadius(innerRadius)
    .outerRadius(radius - 10);

  const arcHover = d3.arc()
    .innerRadius(innerRadius)
    .outerRadius(radius - 2);

  const slices = svg.selectAll('.slice')
    .data(pie(rootCauses))
    .enter()
    .append('g')
    .attr('class', 'slice');

  // Color fill
  slices.append('path')
    .attr('d', arc)
    .attr('fill', d => d.data.colorHex)
    .attr('stroke', '#fff')
    .attr('stroke-width', 2)
    .style('opacity', 0)
    .transition()
    .duration(800)
    .delay((d, i) => i * 150)
    .style('opacity', 1)
    .attrTween('d', function(d) {
      const i = d3.interpolate({ startAngle: d.startAngle, endAngle: d.startAngle }, d);
      return function(t) { return arc(i(t)); };
    });

  // Pattern overlay
  slices.append('path')
    .attr('d', arc)
    .attr('fill', (d, i) => `url(#${patterns[i].id})`)
    .attr('opacity', 0.3)
    .attr('pointer-events', 'none')
    .style('opacity', 0)
    .transition()
    .duration(800)
    .delay((d, i) => i * 150)
    .style('opacity', 0.3);

  // Percentage labels
  slices.append('text')
    .attr('transform', d => `translate(${arc.centroid(d)})`)
    .attr('text-anchor', 'middle')
    .attr('dominant-baseline', 'middle')
    .attr('font-size', '13px')
    .attr('font-weight', '800')
    .attr('fill', '#fff')
    .attr('paint-order', 'stroke')
    .attr('stroke', 'rgba(0,0,0,0.3)')
    .attr('stroke-width', '2px')
    .text(d => d.data.percentage + '%')
    .style('opacity', 0)
    .transition()
    .duration(600)
    .delay((d, i) => i * 150 + 400)
    .style('opacity', 1);

  // Center text
  svg.append('text')
    .attr('text-anchor', 'middle')
    .attr('dominant-baseline', 'middle')
    .attr('font-size', '14px')
    .attr('font-weight', '700')
    .attr('fill', '#1a202c')
    .text('Root Causes');

  svg.append('text')
    .attr('text-anchor', 'middle')
    .attr('y', 20)
    .attr('font-size', '11px')
    .attr('fill', '#718096')
    .text('All Facilities');

  // Tooltip
  const tooltip = d3.select('body').select('.chart-tooltip').node()
    ? d3.select('body').select('.chart-tooltip')
    : d3.select('body').append('div').attr('class', 'chart-tooltip');

  slices.selectAll('path:first-child')
    .on('mouseover', function(event, d) {
      d3.select(this).transition().duration(200).attr('d', arcHover);
      tooltip.html(`
        <div class="tooltip-title">${d.data.category}</div>
        <div><span class="tooltip-value">${d.data.percentage}%</span> of discrepancies</div>
        <div style="margin-top:6px;font-size:11px;opacity:0.8">
          ${d.data.examples.slice(0, 2).map(e => '&bull; ' + e).join('<br>')}
        </div>
      `).classed('visible', true);
    })
    .on('mousemove', function(event) {
      tooltip
        .style('left', (event.pageX + 15) + 'px')
        .style('top', (event.pageY - 10) + 'px');
    })
    .on('mouseout', function(event, d) {
      d3.select(this).transition().duration(200).attr('d', arc);
      tooltip.classed('visible', false);
    });
}
