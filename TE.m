% Given two time-series T, S and one integer time-delay, this function
% returns the transfer entropy from S to T with the given time-delay
% between T_future and T_past. Transfer entropy normalized by entropy of
% the target time-series is also calculated.
%
% Output is a scalar in units of bits.
%
% This function can only take discrete time-series.

function [transfer_entropy, normed_TE] = TE(target, source, delay)
    % Ensure input time-series are column vectors.
%     if size(target,1) < size(target,2)
%         str = input('Target input vector has a greater number of columns than rows. Each column should contain the entire time-series of a single neuron. Transpose input matrix? y/n: ','s');
%         if str == 'y'
%             target = target';
%         end
%     end
%     if size(source,1) < size(source,2)
%         str = input('Source input vector has a greater number of columns than rows. Each column should contain the entire time-series of a single neuron. Transpose input matrix? y/n: ','s');
%         if str == 'y'
%             source = source';
%         end
%     end
    % Check if inputs are of the same length.
%     if size(target,1)~= size(source,1)
%         error('Time-series are not of equal length.')
%     elseif (round(delay)~=delay) || (delay<1)
%         error('Input time-delay is not a positive integer.')
%     end
    % Truncate at beginning or end of time-series to create time-delay.
    target_future = target;
    target_future(1:delay,:) = [];
    target_past = target;
    target_past((size(target,1)-delay+1):size(target,1),:) = [];
    source_past = source;
    source_past((size(source,1)-delay+1):size(source,1),:) = [];
    transfer_entropy = cond_MI(source_past, target_future, target_past);
    % Normalize by entropy of target time-series.
    target_entropy = 0;
    for i = unique(target_future, 'row')'
        prob = sum(target_future==i')/size(target_future,1);
        target_entropy = target_entropy - prob * log(prob) / log(2);
    end
    if target_entropy == 0
%          disp('Target time-series has zero entropy. Using unnormalized transfer entropy.')
        normed_TE = transfer_entropy;
    else
        normed_TE = transfer_entropy / target_entropy;
    end
end