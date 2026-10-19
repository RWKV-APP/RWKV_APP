bool isCurrentGenerationResponse(int? responseRequestId, int? generationRequestId) {
  if (responseRequestId == null || generationRequestId == null) return true;
  return responseRequestId >= generationRequestId;
}
