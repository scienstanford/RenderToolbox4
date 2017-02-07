function fig = rtbPlotManyRecipeComparisons(comparisons, varargin)
%% Plot a many recipe comparisons from rtbCompareManyRecipes().
%
% fig = fig = rtbPlotManyRecipeComparisons(comparisons) makes a plot to
% visualize the given struct array of comparison results, as produced by
% rtbCompareManyRecipes().
%
%%% RenderToolbox4 Copyright (c) 2012-2017 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.KeepUnmatched = true;
parser.addRequired('comparisons', @isstruct);
parser.addParameter('fig', figure());
parser.addParameter('figureWidth', 1000, @isnumeric);
parser.addParameter('nRows', 25, @isnumeric);
parser.addParameter('correlationMin', 0.8, @isnumeric);
parser.addParameter('correlationStep', 0.05, @isnumeric);
parser.addParameter('errorMax', 3, @isnumeric);
parser.addParameter('errorStep', 0.5, @isnumeric);
parser.parse(comparisons, varargin{:});
comparisons = parser.Results.comparisons;
fig = parser.Results.fig;
figureWidth = parser.Results.figureWidth;
nRows = parser.Results.nRows;
correlationMin = parser.Results.correlationMin;
correlationStep = parser.Results.correlationStep;
errorMax = parser.Results.errorMax;
errorStep = parser.Results.errorStep;


%% Sort the summary by size of error.
goodComparisons = comparisons([comparisons.isGoodComparison]);
relNormDiff = [goodComparisons.relNormDiff];
errorStat = [relNormDiff.max];
[~, order] = sort(errorStat);
goodComparisons = goodComparisons(order);


%% Set up the figure.
figureName = sprintf('Summary of %d rendering comparisons', ...
    numel(goodComparisons));
set(fig, ...
    'Name', figureName, ...
    'NumberTitle', 'off');

position = get(fig, 'Position');
if position(3) < figureWidth
    position(3) = figureWidth;
    set(fig, 'Position', position);
end

%% Summary of correlation coefficients.
correlationTicks = correlationMin : correlationStep : 1;
correlationTickLabels = num2cell(correlationTicks);
correlationTickLabels{1} = '<=';
correlation = [goodComparisons.corrcoef];
correlation(correlation < correlationMin) = correlationMin;

renderingsA = [goodComparisons.renderingA];
names = {renderingsA.identifier};
nLines = numel(names);
ax(1) = subplot(1, 3, 2, ...
    'Parent', fig, ...
    'YTick', 1:nLines, ...
    'YTickLabel', names, ...
    'YGrid', 'on', ...
    'XLim', [correlationTicks(1), correlationTicks(end)], ...
    'XTick', correlationTicks, ...
    'XTickLabel', correlationTickLabels);
line(correlation, 1:nLines, ...
    'Parent', ax(1), ...
    'LineStyle', 'none', ...
    'Marker', 'o', ...
    'Color', [0 0 1])
xlabel(ax(1), 'correlation');


%% Overall title.
name = sprintf('%s vs %s', ...
    goodComparisons(1).renderingA.sourceFolder, ...
    goodComparisons(1).renderingB.sourceFolder);
title(ax(1), name, 'Interpreter', 'none');


%% Summary of mean and max subpixel differences.
errorTicks = 0 : errorStep : errorMax;
errorTickLabels = num2cell(errorTicks);
errorTickLabels{end} = '>=';

relNormDiff = [goodComparisons.relNormDiff];
maxes = [relNormDiff.max];
means = [relNormDiff.mean];
maxes(maxes > errorMax) = errorMax;
means(means > errorMax) = errorMax;
ax(2) = subplot(1, 3, 3, ...
    'Parent', fig, ...
    'YTick', 1:nLines, ...
    'YTickLabel', 1:nLines, ...
    'YAxisLocation', 'right', ...
    'YGrid', 'on', ...
    'XLim', [errorTicks(1), errorTicks(end)], ...
    'XTick', errorTicks, ...
    'XTickLabel', errorTickLabels);
line(maxes, 1:nLines, ...
    'Parent', ax(2), ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'Color', [1 0 0])
line(means, 1:nLines, ...
    'Parent', ax(2), ...
    'LineStyle', 'none', ...
    'Marker', 'o', ...
    'Color', [0 0 0])
legend(ax(2), 'max', 'mean', 'Location', 'northeast');
xlabel(ax(2), 'relative diff');


%% Let the user scroll both axes at the same time.
scrollerData.axes = ax;
scrollerData.nLinesAtATime = nRows;
scroller = uicontrol( ...
    'Parent', fig, ...
    'Units', 'normalized', ...
    'Position', [.95 0 .05 1], ...
    'Callback', @scrollAxes, ...
    'Min', 1, ...
    'Max', max(2, nLines), ...
    'Value', nLines, ...
    'Style', 'slider', ...
    'SliderStep', [1 2], ...
    'UserData', scrollerData);
scrollAxes(scroller, []);


%% Scroll summary axes together.
function scrollAxes(object, event)
scrollerData = get(object, 'UserData');
topLine = get(object, 'Value');
yLimit = topLine + [-scrollerData.nLinesAtATime 1];
set(scrollerData.axes, 'YLim', yLimit);
