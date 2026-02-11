// ============================================
// D3.js Verification Factor Bar Chart
// ============================================
import { facilities, indicators, verificationFactors, getVFColor, getVFStatus } from '../data.js';

export function renderVerificationFactorChart(containerId, indicatorId = 'fp') {
  const container = document.getElementById(containerId);
  if (!container) return;

  container.innerHTML = '';

  const margin = { top: 30, right: 30, bottom: 80, left: 60 };
  const width = container.clientWidth - margin.left - margin.right;
  const height = 400 - margin.top - margin.bottom;

  const svg = d3.select(`#${containerId}`)
    .append('svg')
    .attr('viewBox', `0 0 ${width + margin.left + margin.right} ${height + margin.top + margin.bottom}`)
    .attr('preserveAspectRatio', 'xMidYMid meet')
    .attr('role', 'img')
    .attr('aria-label', `Verification Factor chart for ${indicators.find(i => i.id === indicatorId)?.name || indicatorId}`)
    .append('g')
    .attr('transform', `translate(${margin.left},${margin.top})`);

  // Defs for patterns (colorblind accessibility)
  const defs = svg.append('defs');

  // Stripe pattern for over-reporting
  defs.append('pattern')
    .attr('id', 'stripes-orange')
    .attr('patternUnits', 'userSpaceOnUse')
    .attr('width', 6).attr('height', 6)
    .append('path')
    .attr('d', 'M0,6 L6,0')
    .attr('stroke', '#FC8D62')
    .attr('stroke-width', 1.5);

  // Dot pattern for under-reporting
  defs.append('pattern')
    .attr('id', 'dots-purple')
    .attr('patternUnits', 'userSpaceOnUse')
    .attr('width', 6).attr('height', 6)
    .append('circle')
    .attr('cx', 3).attr('cy', 3).attr('r', 1.5)
    .attr('fill', '#8DA0CB');

  const data = facilities.map(f => ({
    ...f,
    vf: verificationFactors[f.id][indicatorId],
    status: getVFStatus(verificationFactors[f.id][indicatorId]),
    color: getVFColor(verificationFactors[f.id][indicatorId])
  }));

  // Scales
  const x = d3.scaleBand()
    .domain(data.map(d => d.id))
    .range([0, width])
    .padding(0.25);

  const y = d3.scaleLinear()
    .domain([60, 130])
    .range([height, 0]);

  // Tolerance band (90-110%)
  svg.append('rect')
    .attr('x', 0)
    .attr('y', y(110))
    .attr('width', width)
    .attr('height', y(90) - y(110))
    .attr('fill', '#66C2A5')
    .attr('opacity', 0.08)
    .attr('rx', 4);

  // Tolerance band labels
  svg.append('text')
    .attr('x', width + 5)
    .attr('y', y(110) + 4)
    .attr('font-size', '10px')
    .attr('fill', '#66C2A5')
    .attr('font-weight', '600')
    .text('110%');

  svg.append('text')
    .attr('x', width + 5)
    .attr('y', y(90) + 4)
    .attr('font-size', '10px')
    .attr('fill', '#66C2A5')
    .attr('font-weight', '600')
    .text('90%');

  // 100% reference line
  svg.append('line')
    .attr('x1', 0).attr('x2', width)
    .attr('y1', y(100)).attr('y2', y(100))
    .attr('stroke', '#1a365d')
    .attr('stroke-width', 1)
    .attr('stroke-dasharray', '4,4')
    .attr('opacity', 0.4);

  svg.append('text')
    .attr('x', -8)
    .attr('y', y(100) + 4)
    .attr('font-size', '10px')
    .attr('fill', '#1a365d')
    .attr('font-weight', '600')
    .attr('text-anchor', 'end')
    .text('100%');

  // Gridlines
  svg.selectAll('.gridline')
    .data([70, 80, 90, 100, 110, 120])
    .enter()
    .append('line')
    .attr('x1', 0).attr('x2', width)
    .attr('y1', d => y(d)).attr('y2', d => y(d))
    .attr('stroke', '#e2e8f0')
    .attr('stroke-width', 0.5);

  // Bars
  const bars = svg.selectAll('.bar')
    .data(data)
    .enter()
    .append('g')
    .attr('class', 'bar');

  bars.append('rect')
    .attr('x', d => x(d.id))
    .attr('width', x.bandwidth())
    .attr('y', height)
    .attr('height', 0)
    .attr('fill', d => d.color)
    .attr('rx', 4)
    .attr('ry', 4)
    .transition()
    .duration(800)
    .delay((d, i) => i * 60)
    .attr('y', d => y(Math.max(d.vf, 60)))
    .attr('height', d => height - y(Math.max(d.vf, 60)));

  // Pattern overlay for non-acceptable bars
  bars.each(function(d) {
    if (d.status !== 'acceptable') {
      const patternId = d.status === 'over-reporting' ? 'stripes-orange' : 'dots-purple';
      d3.select(this).append('rect')
        .attr('x', x(d.id))
        .attr('width', x.bandwidth())
        .attr('y', y(Math.max(d.vf, 60)))
        .attr('height', height - y(Math.max(d.vf, 60)))
        .attr('fill', `url(#${patternId})`)
        .attr('opacity', 0.4)
        .attr('rx', 4)
        .attr('pointer-events', 'none');
    }
  });

  // Value labels on bars
  bars.append('text')
    .attr('x', d => x(d.id) + x.bandwidth() / 2)
    .attr('y', d => y(d.vf) - 8)
    .attr('text-anchor', 'middle')
    .attr('font-size', '11px')
    .attr('font-weight', '700')
    .attr('fill', d => d.color === '#66C2A5' ? '#1B9E77' : d.color)
    .attr('opacity', 0)
    .text(d => d.vf + '%')
    .transition()
    .duration(800)
    .delay((d, i) => i * 60 + 400)
    .attr('opacity', 1);

  // X Axis
  svg.append('g')
    .attr('transform', `translate(0,${height})`)
    .call(d3.axisBottom(x).tickFormat(id => {
      const f = facilities.find(f => f.id === id);
      return f ? f.name.split(' ').slice(0, 2).join(' ') : id;
    }))
    .selectAll('text')
    .attr('transform', 'rotate(-35)')
    .attr('text-anchor', 'end')
    .attr('font-size', '10px')
    .attr('fill', '#4a5568');

  // Y Axis
  svg.append('g')
    .call(d3.axisLeft(y).ticks(7).tickFormat(d => d + '%'))
    .selectAll('text')
    .attr('font-size', '10px')
    .attr('fill', '#4a5568');

  // Y Axis label
  svg.append('text')
    .attr('transform', 'rotate(-90)')
    .attr('y', -45)
    .attr('x', -height / 2)
    .attr('text-anchor', 'middle')
    .attr('font-size', '11px')
    .attr('fill', '#718096')
    .text('Verification Factor (%)');

  // Tooltip
  const tooltip = d3.select('body').select('.chart-tooltip').node()
    ? d3.select('body').select('.chart-tooltip')
    : d3.select('body').append('div').attr('class', 'chart-tooltip');

  bars.selectAll('rect:first-child')
    .on('mouseover', function(event, d) {
      const statusLabel = d.status === 'acceptable' ? 'Within tolerance' :
        d.status === 'over-reporting' ? 'Over-reporting (VF < 90%)' : 'Under-reporting (VF > 110%)';
      tooltip.html(`
        <div class="tooltip-title">${d.name}</div>
        <div>${d.district} &bull; ${d.type}</div>
        <div style="margin-top:4px"><span class="tooltip-value">${d.vf}%</span> VF</div>
        <div style="margin-top:2px;font-size:11px;opacity:0.8">${statusLabel}</div>
      `).classed('visible', true);
      d3.select(this).attr('opacity', 0.8);
    })
    .on('mousemove', function(event) {
      tooltip
        .style('left', (event.pageX + 15) + 'px')
        .style('top', (event.pageY - 10) + 'px');
    })
    .on('mouseout', function() {
      tooltip.classed('visible', false);
      d3.select(this).attr('opacity', 1);
    });

  // Summary stats
  const acceptable = data.filter(d => d.status === 'acceptable').length;
  const pct = Math.round((acceptable / data.length) * 100);
  updateVFSummary(acceptable, data.length, pct);
}

function updateVFSummary(acceptable, total, pct) {
  const el = document.getElementById('vf-summary');
  if (el) {
    el.innerHTML = `<strong>${acceptable}</strong> of <strong>${total}</strong> facilities (${pct}%) within the <span style="color:var(--cb-teal-dark)">90-110% tolerance band</span>`;
  }
}
