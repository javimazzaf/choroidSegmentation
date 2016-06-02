function [mn, sd] = maskMeanAndSd(value,weight,msk)
%Computes weighted mean and standard deviation of "value" within msk

  mn  = sum(value(msk) .* weight(msk)) / sum(weight(msk));
  sd  = sqrt(sum(value(msk).^2 .* weight(msk)) / sum(weight(msk)) - mn^2);
end