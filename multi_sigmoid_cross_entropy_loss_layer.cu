#include <algorithm>
#include <vector>

#include "caffe/layers/multi_sigmoid_cross_entropy_loss_layer.hpp"
#include "caffe/util/math_functions.hpp"

namespace caffe {

template <typename Dtype>
void MultiSigmoidCrossEntropyLossLayer<Dtype>::Forward_gpu(
    const vector<Blob<Dtype>*>& bottom, const vector<Blob<Dtype>*>& top) {
  // The forward pass computes the sigmoid outputs.
  sigmoid_bottom_vec_[0] = bottom[0];
  sigmoid_layer_->Forward(sigmoid_bottom_vec_, sigmoid_top_vec_);
  // Compute the loss (negative log likelihood)
  // Stable version of loss computation from input data
  const Dtype* input_data = bottom[0]->cpu_data();
  const Dtype* target = bottom[1]->cpu_data();
  int valid_count = 0;
  Dtype loss = 0;
  for (int i = 0; i < bottom[0]->count(); ++i) {
    if (target[i] != 0){
        loss -= input_data[i] * ((target[i] > 0) - (input_data[i] >= 0)) -
          log(1 + exp(input_data[i] - 2 * input_data[i] * (input_data[i] >= 0)));
        ++valid_count;
    }
    if (top.size() >= 1) {
      top[0]->mutable_cpu_data()[0] = loss / valid_count;
    }
  }
  normalizer_ = get_normalizer(normalization_, valid_count);
  //top[0]->mutable_cpu_data()[0] = loss / normalizer_;
}


template <typename Dtype>
void MultiSigmoidCrossEntropyLossLayer<Dtype>::Backward_gpu(
    const vector<Blob<Dtype>*>& top, const vector<bool>& propagate_down,
    const vector<Blob<Dtype>*>& bottom) {
    Backward_cpu(top, propagate_down, bottom);
}

INSTANTIATE_LAYER_GPU_FUNCS(MultiSigmoidCrossEntropyLossLayer);


}  // namespace caffe