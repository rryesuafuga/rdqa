// ============================================
// D3.js Gantt Timeline — Monthly RDQA Cycle
// ============================================
import { timelinePhases } from '../data.js';

export function renderTimeline(containerId) {
  const container = document.getElementById(containerId);
  if (!container) return;

  container.innerHTML = '';

  const margin = { top: 30, right: 30, bottom: 40, left: 180 };
  const width = container.clientWidth - margin.left - margin.right;
  const barHeight = 50;
  const height = timelinePhases.length * (barHeight + 20) + 20;

  const svg = d3.select(`#${containerId}`)
    .append('svg')
    .attr('viewBox', `0 0 ${width + margin.left + margin.right} ${height + margin.top + margin.bottom}`)
    .attr('preserveAspectRatio', 'xMidYMid meet')
    .attr('role', 'img')
    .attr('aria-label', 'Monthly RDQA cycle timeline showing three phases across 25 days')
    .append('g')
    .attr('transform', `translate(${margin.left},${margin.top})`);

  const x = d3.scaleLinear()
    .domain([0, 26])
    .range([0, width]);

  const y = d3.scaleBand()
    .domain(timelinePhases.map(d => d.name))
    .range([0, height])
    .padding(0.3);

  // Day grid lines
  for (let day = 1; day <= 25; day++) {
    svg.append('line')
      .attr('x1', x(day)).attr('x2', x(day))
      .attr('y1', 0).attr('y2', height)
      .attr('stroke', '#e2e8f0')
      .attr('stroke-width', 0.5);
  }

  // Day labels
  [1, 3, 4, 10, 14, 18, 19, 22, 25].forEach(day => {
    svg.append('text')
      .attr('x', x(day))
      .attr('y', height + 20)
      .attr('text-anchor', 'middle')
      .attr('font-size', '10px')
      .attr('fill', '#718096')
      .text('Day ' + day);
  });

  // Phase bars
  const bars = svg.selectAll('.phase-bar')
    .data(timelinePhases)
    .enter()
    .append('g')
    .attr('class', 'phase-bar');

  // Background bars
  bars.append('rect')
    .attr('x', 0)
    .attr('y', d => y(d.name))
    .attr('width', 0)
    .attr('height', y.bandwidth())
    .attr('fill', d => d.colorHex)
    .attr('opacity', 0.15)
    .attr('rx', 6)
    .transition()
    .duration(800)
    .delay((d, i) => i * 200)
    .attr('width', width);

  // Phase bars
  bars.append('rect')
    .attr('x', d => x(d.start))
    .attr('y', d => y(d.name))
    .attr('width', 0)
    .attr('height', y.bandwidth())
    .attr('fill', d => d.colorHex)
    .attr('rx', 6)
    .transition()
    .duration(1000)
    .delay((d, i) => i * 200 + 300)
    .attr('width', d => x(d.end + 1) - x(d.start));

  // Phase labels (left)
  bars.append('text')
    .attr('x', -10)
    .attr('y', d => y(d.name) + y.bandwidth() / 2)
    .attr('text-anchor', 'end')
    .attr('dominant-baseline', 'middle')
    .attr('font-size', '12px')
    .attr('font-weight', '600')
    .attr('fill', '#1a202c')
    .text(d => d.name);

  // Day range labels on bars
  bars.append('text')
    .attr('x', d => x(d.start) + (x(d.end + 1) - x(d.start)) / 2)
    .attr('y', d => y(d.name) + y.bandwidth() / 2)
    .attr('text-anchor', 'middle')
    .attr('dominant-baseline', 'middle')
    .attr('font-size', '13px')
    .attr('font-weight', '700')
    .attr('fill', '#fff')
    .attr('paint-order', 'stroke')
    .attr('stroke', 'rgba(0,0,0,0.15)')
    .attr('stroke-width', '2px')
    .text(d => `Days ${d.days}`)
    .attr('opacity', 0)
    .transition()
    .duration(600)
    .delay((d, i) => i * 200 + 800)
    .attr('opacity', 1);

  // Task counts
  bars.append('text')
    .attr('x', d => x(d.end + 1) + 10)
    .attr('y', d => y(d.name) + y.bandwidth() / 2)
    .attr('dominant-baseline', 'middle')
    .attr('font-size', '10px')
    .attr('fill', '#718096')
    .text(d => d.tasks.length + ' tasks');

  // Tooltip for tasks
  const tooltip = d3.select('body').select('.chart-tooltip').node()
    ? d3.select('body').select('.chart-tooltip')
    : d3.select('body').append('div').attr('class', 'chart-tooltip');

  bars.selectAll('rect:nth-child(2)')
    .on('mouseover', function(event, d) {
      tooltip.html(`
        <div class="tooltip-title">${d.name}</div>
        <div style="margin-bottom:6px">Days ${d.days} of each month</div>
        ${d.tasks.map(t => `<div style="font-size:11px;margin-bottom:2px">&bull; ${t}</div>`).join('')}
      `).classed('visible', true);
    })
    .on('mousemove', function(event) {
      tooltip.style('left', (event.pageX + 15) + 'px').style('top', (event.pageY - 10) + 'px');
    })
    .on('mouseout', function() {
      tooltip.classed('visible', false);
    });
}
