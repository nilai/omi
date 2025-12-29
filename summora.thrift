// 有几个约定
// 服务端域名为：memopin.ai
// 1. 所有接口都需要传一下user_id，放在header中
// 2. 服务端接口返回值都会包括base_resp结构。code为0的时候代表成功返回；如果是返回1XXXX，代表请求参数错误等客户端错误；如果是返回2XXXX，代表服务端错误
// 3. logid可以在日志中打印，方便查问题。

// 命名空间定义
namespace py summora

struct BaseResp {
    1: i32 code,
    2: string message,
    3: string logid,
}

struct SpeakerStruct {
    1: string id,
    2: string name,
    3: string avatar,
    4: bool is_temporary, // 是否是已经录入声纹的说话人，false为已经录入
    5: bool myself_voice,
    6: string audio_url,
    7: i32 duration,  // 声音时长，单位s
}

struct SpeakerWithDetailStruct {
    1: SpeakerStruct speaker,
    2: string summary,
    3: i64 last_memory_at,
    4: i32: memory_total
}

struct TodoStruct {
    1: string id,
    2: string title,
    3: SpeakerStruct owner,
    4: string priority,
    5: string deadline,
    6: i32 status,
}

enum MemoryType {
  SUMMARY = 1,
  ONLY_RECORD = 2,
  INSIGHT = 3,
  AI_EXPERT = 4,
}

struct AiExpertMemoryStruct {
    1: string content, // markdwon格式
}

struct InsightMemoryStruct {
    1: string content, // markdwon格式
}

struct OnlyRecordMemoryStruct {
    1: string record_file, // 本地保存的文件名
}

struct RecordConversationStruct {
    1: string id,
    2: SpeakerStruct speaker,
    3: string content,
    4: string time,
}

struct SummaryMemoryStruct {
    1: list<SpeakerStruct> participants,
    2: i32: participants_cnt,
    2: string record_url, // 录音地址
    3: string summary, // markdown格式
    4: list<RecordConversationStruct> transcript,
    5: list<TodoStruct> todos,
    6: i32: status,
    7: string: source,
}

struct MemoryStruct {
    1: string id,
    2: i64 create_at,
    3: string title,
    4: MemoryType type,
    5: string label, // 会议纪要、今日运势之类的
    6: string label_color,  // 格式为 #467db4
    7: list<string> custom_labels,
    8: string content,
    9: i32 duration, // 单位是s
    10: SummaryMemoryStruct summary_content,
    11: OnlyRecordMemoryStruct only_record_content,
    12: InsightMemoryStruct insight_content,
    13: AiExpertMemoryStruct ai_expert_content,
}


struct MemoStruct {
    1: string id,
    2: string title,
    3: string content,
    4: list<string> tags,
    5: i64 create_at,
    6: i64 relate_memory_id, // 如果没有关联的记忆，则为0
}

struct TemplateStruct {
    1: string id,
    2: string title,
    3: string icon,
    4: string type,
    5: string prompt,
    6: bool custome_template,  // 为true是用户自己创建模板
}

struct ExpertStruct {
    1: string id,
    2: string name,
    3: string avatar,
    4: string label,
    5: string about,
    6: list<string> capabilities,
    7: string chat_prompt,
    8: string feed_prompt,
    9: string feedback_cron_at,
    10: bool cron_send,
}

struct ExpertMergeUserStruct {
    1: ExpertStruct expert,
    2: bool is_add,
}

struct UserAISettings {
    1: string appellation, // AI如何称呼您
    2: string profession, // 职业
    3: string ai_personality, // AI人格
    4: string response_style,
    5: string custom_prompt,
    6: bool right_now_transcribe,
}

struct UserStruct {
    1: string user_name,
    2: string email,
    3: string avatar,
    4: string phone,
    5: string brithday,
    6: UserAISettings ai_settings,
}

struct ConversationStruct {
    1: SpeakerStruct speaker,
    2: string content,
    3: string time,
}

struct ConversationHeaderStruct {
    1: string id,
    2: string title,
}

///// 

struct GetMemoryListResponse {
    1: list<MemoryStruct> memorys,
    2: bool has_more,
    3: i32 memory_total,
    255: BaseResp base_resp,
}

struct GetMemoryListRequest {
    1: optional string day,  // 20250-12-14
    2: i32 page_size,
    3: string cursor,
}

struct GetMemoryDaysRequest {
    1: string month, // 如2025-11、2025-01
}

struct GetMemoryDaysResponse {
    1: list<string> days; // 返回有记录的日期列表, [2025-11-10, 2025-11-11, 2025-11-15]
    255: BaseResp base_resp,
}

struct GetMemoryDetailResponse {
    1: MemoryStruct memory,
    255: BaseResp base_resp,
}

struct GetMemoryDetailRequest {
    1: string memory_id,
}

struct GetInsightListRequest {
    1: i32 page_size,
    2: string cursor,
}

struct GetInsightListResponse {
    1: list<MemoryStruct> insights,
    2: bool has_more,
    255: BaseResp base_resp,
}

struct CreateRecordRequest {
    1: string record_file,
    2: i64 create_at,
    3: i32 duration, // 单位是s
    4: string source,
}

struct CreateRecordResponse {
    1: string memory_id,
    2: string record_url,
    255: BaseResp base_resp,
}

struct GetUploadRecordUrlRequest {
    1: string content_type,
}

struct GetUploadRecordUrlResponse {
    1: string upload_url,
    2: string uri,
    255: BaseResp base_resp,
}

struct SummaryRecordRequest {
    1: string memory_id,
    2: string record_url,
    3: i64 record_memo_at,  // 针对开启录音情况下的memo创建，这里给到memo发生时录音具体时间点，相对时间，即录音的第几秒
    4: optional string template_id,  // 总结需要的模板
}

struct SummaryRecordResponse {
    255: BaseResp base_resp,
}

struct GetSummaryStatusRequest {
    1: string memory_id,
}

struct GetSummaryStatusResponse {
    1: i32: status,
    255: BaseResp base_resp,
}

struct SearchMemoryRequest {
    1: string search_content,
}

struct SearchMemoryResponse {
    1: list<MemoryStruct> memorys,
    255: BaseResp base_resp,
}

struct ShareMemoryRequest {
    1: string memory_id,
}

struct ShareMemoryResponse {
    1: string id,
    2: string share_code,
    3: string share_url,
    4: string short_url,
    5: i64 expires_at,
    6: i64 create_at,
    255: BaseResp base_resp,
}

struct DeleteMemoryRequest {
    1: string memory_id
}

struct DeleteMemoryResponse {
    255: BaseResp base_resp,
}

struct RenameMemoryRequest {
    1: string memory_id,
    2: string title,
}

struct RenameMemoryResponse {
    255: BaseResp base_resp,
}

struct MemoryAddTagRequest {
    1: string memory_id,
    2: string label,
}

struct MemoryAddTagResponse {
    255: BaseResp base_resp,
}

struct GetSummaryListRequest {
    1: i32 page_size,
    2: string cursor,
}

struct GetSummaryListResponse {
    1: list<MemoryStruct> summarys,
    2: bool has_more,
    255: BaseResp base_resp,
}

struct AppendMemoryRequest {
    1: list<string> memory_ids,
}

struct AppendMemoryResponse {
    255: BaseResp base_resp,
}

struct GetMemoListRequest {
    1: i32 page_size,
    2: string cursor,
}

struct GetMemoListResponse {
    1: list<MemoStruct> memos,
    2: bool has_more,
    255: BaseResp base_resp,
}

struct GetMemoDetailRequest {
    1: string memo_id,
}

struct GetMemoDetailResponse {
    1: MemoStruct memo,
    255: BaseResp base_resp,
}

struct CreateMemoWithRecordRequest {
    1: string record_url, // 针对没开启录音情况下的memo创建
    2: i64 create_at,
}

struct CreateMemoWithRecordResponse {
    255: BaseResp base_resp,
}

struct CreateMemoWithTextRequest {
    1: string content,
    2: i64 create_at,
}

struct CreateMemoWithTextResponse {
    255: BaseResp base_resp,
}

struct UpdateMemoRequest {
    1: string memo_id,
    2: string content,
}

struct UpdateMemoResponse {
    255: BaseResp base_resp,
}

struct DeleteMemoRequest {
    1: string memo_id,
}

struct DeleteMemoResponse {
    255: BaseResp base_resp,
}

struct GetTodoListRequest {
    1: i32 page_size,
    2: string cursor,
}

struct GetTodoListResponse {
    1: list<TodoStruct> todos,
    2: bool has_more,
    255: BaseResp base_resp,
}

struct CreateTodoRequest {
    1: string title,
    2: string owner_id,
    3: string priority,
    4: string deadline,
}

struct CreateTodoResponse {
    255: BaseResp base_resp,
}

struct DoneTodoRequest {
    1: string todo_id,
}

struct DoneTodoResponse {
    255: BaseResp base_resp,
}

struct UpdateTodoRequest {
    1: string todo_id,
    2: string title,
    3: string priority,
    4: string deadline,
    5: string is_completed,
}

struct UpdateTodoResponse {
    255: BaseResp base_resp,
}

struct DeleteTodoRequest {
    1: string todo_id,
}

struct DeleteTodoResponse {
    255: BaseResp base_resp,
}

struct CreateConversationRequest {
    1: optional string title,
    2: string expert_id, // 专家模型ID, 不用的话，为空字符串
    3: string memory_id, // 对应的记忆id，不用的话，为空字符串。针对记忆总结的场景
    4: string template_id, // 对应的模板id，不用的话，为空字符串
    5: string speaker_id, // 对应人物的id，没有的话，为空字符串。针对AI分析助手的场景
}

struct CreateConversationResponse {
    1: string conversation_id,
    2: string greet,
    255: BaseResp base_resp,
}

struct ChatRequest {
    1: string message,  // 输入的内容
    2: string conversation_id,
}

struct ChatResponse {
    // streaming 接口
}

struct GetConversationListRequest {
    1: i32 page_size,
    2: string cursor,
}

struct GetConversationListResponse {
    1: list<ConversationHeaderStruct> conversations,
    2: bool has_more,
    255: BaseResp base_resp,
}

struct GetConversationDetailRequest {
    1: string conversation_id,
}

struct GetConversationDetailResponse {
    1: string title,
    2: list<ConversationStruct> contents,
    255: BaseResp base_resp,
}

struct TranscriptRequest {
    1: string audio_url,
}

struct TranscriptResponse {
    1: string content,
    255: BaseResp base_resp,
}

struct GetChatSuggestionResponse {
    1: map<map<string, list<string>>> suggestion, // 从记忆仓库进入的AI助理 key为 chat_with_speaker;
    // 从Memory进入的AI助理 key为chat_with_memory；直接进入AI 助理 key为 normal
    255: BaseResp base_resp,
}

struct GetChatSuggestionRequest {
}

struct GetConversationTitleResponse {
    1: string title,
    255: BaseResp base_resp,
}

struct GetConversationTitleRequest {
    1: string conversation_id,
}

struct AddSpeakerRequest {
    1: string audio_url,
    2: string name,
    3: string avatar, // 可以为空
    4: bool myself_voice,
    5: i32 duration,  // 声音时长，单位s
}

struct AddSpeakerResponse {
    255: BaseResp base_resp,
}

struct MarkSpeakerRequest {
    1: string memory_id,
    2: string template_speaker_name, // 在记忆的对话的临时名字
    3: string name, // 设置的名字
    4: string avatar, // 可以为空
}

struct MarkSpeakerResponse {
    255: BaseResp base_resp,
}

struct GetSpeakerListRequest {
    1: i32 page_size,
    2: string cursor,
}

struct GetSpeakerListResponse {
    1: list<SpeakerStruct> speakers,
    2: bool has_more,
    255: BaseResp base_resp,
}

struct GetSpeakerListWithDetailRequest {
    1: i32 page_size,
    2: string cursor,
}

struct GetSpeakerListWithDetailResponse {
    1: list<SpeakerWithDetailStruct> speakers,
    2: bool has_more,
    255: BaseResp base_resp,
}

struct GetSpeakerDetailRequest {
    1: string speaker_id,
}

struct GetSpeakerDetailResponse {
    1: SpeakerStruct speaker,
    2: list<MemoryStruct> memorys,
    3: i32 memory_total,
    255: BaseResp base_resp,
}

struct DeleteSpeakerRequest {
    1: string speaker_id,
}

struct DeleteSpeakerResponse {
    255: BaseResp base_resp,
}

struct UpdateSpeakerResponse {
    255: BaseResp base_resp,
}

struct UpdateSpeakerRequest {
    1: string speaker_id,
    2: optional string name,
    3: optional string avatar,
}

struct GetExpertListRequest {
    1: string type,
    2: i32 page_size,
    3: string cursor,
}

struct GetExpertListResponse {
    1: list<ExpertMergeUserStruct> experts,
    2: bool has_more,
    255: BaseResp base_resp,
}

struct GetExpertDetailRequest {
    1: string expert_id,
}

struct GetExpertDetailResponse {
    1: ExpertMergeUserStruct expert,
    255: BaseResp base_resp,
}

struct CreateExpertRequest {
    1: string name,
    2: string avatar,
    3: string about,
    4: string type,
    5: list<string> capabilities,
    6: string chat_prompt,
    7: string feedback_prompt,
    8: optional feedback_cron_at,
    9: optional bool cron_send,
}

struct CreateExpertResponse {
    255: BaseResp base_resp,
}


struct UpdateExpertRequest {
    1: string expert_id,
    2: optional feedback_cron_at,
    3: optional bool cron_send,
}

struct UpdateExpertResponse {
    255: BaseResp base_resp,
}

struct UserAddExpertRequest {
    1: string expert_id,
    2: optional feedback_cron_at,
    3: optional bool cron_send,
}

struct UserAddExpertResponse {
    255: BaseResp base_resp,
}

struct UserCancelExpertRequest {
    1: string expert_id,
}

struct UserCancelExpertResponse {
    255: BaseResp base_resp,
}

struct GetTemplateListRequest {
    1: i32 page_size,
    2: string cursor,
}

struct GetTemplateListResponse {
    1: list<TemplateStruct> recommend_templates,
    2: list<TemplateStruct> custom_templates,
    3: optional TemplateStruct recent_template,
    4: map<string, list<TemplateStruct>> templates,
    5: bool has_more,
    255: BaseResp base_resp,
}

struct GetTemplateDetailRequest {
    1: string template_id,
}

struct GetTemplateDetailResponse {
    1: TemplateStruct template,
    255: BaseResp base_resp,
}

struct CreateTemplateRequest {
    1: optional string template_id,
    2: string title,
    3: string icon,
    4: string prompt,
    5: string type,
    6: bool set_default, // 是否设置为默认模板
}

struct CreateTemplateResponse {
    255: BaseResp base_resp,
}

struct SetTemplateDefaultRequest {
    1: string template_id,
}

struct SetTemplateDefaultResponse {
    255: BaseResp base_resp,
}

struct GetUserProfileResponse {
    1: UserStruct user,
    255: BaseResp base_resp,
}

struct GetUserProfileRequest {
}

struct UpdateUserProfileRequest {
    1: string name, // 为空则不更新
    2: string email,
    3: string avatar,
    4: string phone,
    5: string brithday,
}

struct UpdateUserProfileResponse {
    255: BaseResp base_resp,
}

struct UpdateUserAiSettingRequest {
    1: string appellation, // AI如何称呼您
    2: string profession, // 职业
    3: string ai_personality, // AI人格
    4: string response_style,
    5: string custom_prompt,
    6: optional bool right_now_transcribe,  // 是否开启录音之后立即转写，为null的话，就表明不更新此字段
}

struct UpdateUserAiSettingResponse {
    255: BaseResp base_resp,
}

service AppService {
    // 记忆相关接口
    // GET /api/v1/memory/get_list
    GetMemoryListResponse GetMemoryList(1: GetMemoryListRequest req)
    // GET /api/v1/memory/get_days
    GetMemoryDaysResponse GetMemoryDays(1: GetMemoryDaysRequest req)
    // GET /api/v1/memory/get_detail
    GetMemoryDetailResponse GetMemoryDetail(1: GetMemoryDetailRequest req)
    // GET /api/v1/memory/get_insight_list
    GetInsightListResponse GetInsightList(1: GetInsightListRequest req)

    // 主要用于创建录音记录
    // POST /api/v1/memory/create_record
    CreateRecordResponse CreateRecord(1: CreateRecordRequest req)
    // 获取到上传地址，直接put录音文件到这个地址
    // GET /api/v1/memory/get_upload_record_url
    GetUploadRecordUrlResponse GetUploadRecordUrl(1: GetUploadRecordUrlRequest req)
    // POST /api/v1/memory/summary_record
    SummaryRecordResponse SummaryRecord(1: SummaryRecordRequest req)
    // GET /api/v1/memory/summary/get_status
    GetSummaryStatusResponse GetSummaryStatus(1: GetSummaryStatusRequest req)
    // GET /api/v1/memory/search
    SearchMemoryResponse SearchMemory(1: SearchMemoryRequest req)
    // GET /api/v1/memory/share
    ShareMemoryResponse ShareMemory(1: ShareMemoryRequest req)
    // POST /api/v1/memory/delete
    DeleteMemoryResponse DeleteMemory(1: DeleteMemoryRequest req)
    // POST /api/v1/memory/rename
    RenameMemoryResponse RenameMemory(1: RenameMemoryRequest req)
    // POST /api/v1/memory/add_tag
    MemoryAddTagResponse MemoryAddTag(1: MemoryAddTagRequest req)
    // GET /api/v1/memory/get_summary_list
    GetSummaryListResponse GetSummaryList(1: GetSummaryListRequest req)
    // POST /api/v1/memory/append_summary
    AppendMemoryResponse AppendMemory(1: AppendMemoryRequest req)

    // memo相关接口
    // GET /api/v1/memo/get_list
    GetMemoListResponse GetMemoList(1: GetMemoListRequest req)
    // GET /api/v1/memo/get_detail
    GetMemoDetailResponse GetMemoDetail(1: GetMemoDetailRequest req)
    // POST /api/v1/memo/create_with_record
    CreateMemoWithRecordResponse CreateMemoWithRecord(1: CreateMemoWithRecordRequest req)
    // POST /api/v1/memo/create_with_text
    CreateMemoWithTextResponse CreateMemoWithText(1: CreateMemoWithTextRequest req)
    // POST /api/v1/memo/update
    UpdateMemoResponse UpdateMemo(1: UpdateMemoRequest req)
    // POST /api/v1/memo/delete
    DeleteMemoResponse DeleteMemo(1: DeleteMemoRequest req)

    // TODO list相关接口
    // GET /api/v1/todo/get_list
    GetTodoListResponse GetTodoList(1: GetTodoListRequest req)
    // POST /api/v1/todo/create
    CreateTodoResponse CreateTodo(1: CreateTodoRequest req)
    // POST /api/v1/todo/done
    DoneTodoResponse DoneTodo(1: DoneTodoRequest req)
    // POST /api/v1/todo/update
    UpdateTodoResponse UpdateTodo(1: UpdateTodoRequest req)
    // POST /api/v1/todo/delete
    DeleteTodoResponse DeleteTodo(1: DeleteTodoRequest req)

    // chat相关接口
    // POST /api/v1/chat/create_conversation
    CreateConversationResponse CreateConversation(1: CreateConversationRequest req)
    // POST /api/v1/chat/chat
    ChatResponse Chat(1: ChatRequest req)
    // GET /api/v1/chat/get_conversation_list
    GetConversationListResponse GetConversationList(1: GetConversationListRequest req)
    // GET /api/v1/chat/get_conversation_detail
    GetConversationDetailResponse GetConversationDetail(1: GetConversationDetailRequest req)
    // POST /api/v1/chat/transcript
    TranscriptResponse Transcript(1: TranscriptRequest req)
    // GET /api/v1/chat/suggestion
    GetChatSuggestionResponse GetChatSuggestion(1: GetChatSuggestionRequest req)
    // GET /api/v1/chat/get_title
    GetConversationTitleResponse GetConversationTitle(1: GetConversationTitleRequest req)

    // 说话人 &  记忆仓库相关接口
    // 输入声纹，主动添加speaker
    // POST /api/v1/speaker/add
    AddSpeakerResponse AddSpeaker(1: AddSpeakerRequest req)
    // 在某个记忆中标记某个说话人为xxx
    // POST /api/v1/speaker/mark
    MarkSpeakerResponse MarkSpeaker(1: MarkSpeakerRequest req)
    // GET /api/v1/speaker/get_list
    GetSpeakerListResponse GetSpeakerList(1: GetSpeakerListRequest req)
    // GET /api/v1/speaker/get_list_with_detail
    GetSpeakerListWithDetailResponse GetSpeakerListWithDetail(1: GetSpeakerListWithDetailRequest req)
    // GET /api/v1/speaker/get_detail
    GetSpeakerDetailResponse GetSpeakerDetail(1: GetSpeakerDetailRequest req)
    // POST /api/v1/speaker/delete
    DeleteSpeakerResponse DeleteSpeaker(1: DeleteSpeakerRequest req)
    // POST /api/v1/speaker/update
    UpdateSpeakerResponse UpdateSpeaker(1: UpdateSpeakerRequest req)

    // 专家模型列表
    // GET /api/v1/expert/get_list
    GetExpertListResponse GetExpertList(1: GetExpertListRequest req)
    // GET /api/v1/expert/get_detail
    GetExpertDetailResponse GetExpertDetail(1: GetExpertDetailRequest req)
    // POST /api/v1/expert/create
    CreateExpertResponse CreateExpert(1: CreateExpertRequest req)
    // POST /api/v1/expert/update
    UpdateExpertResponse UpdateExpert(1: UpdateExpertRequest req)
    // POST /api/v1/expert/user_add
    UserAddExpertResponse UserAddExpert(1: UserAddExpertRequest req)
    // POST /api/v1/expert/user_cancel
    UserCancelExpertResponse UserCancelExpert(1: UserCancelExpertRequest req)

    // 模板相关接口
    // GET /api/v1/template/get_list
    GetTemplateListResponse GetTemplateList(1: GetTemplateListRequest req)
    // GET /api/v1/template/get_detail
    GetTemplateDetailResponse GetTemplateDetail(1: GetTemplateDetailRequest req)
    // POST /api/v1/template/create
    CreateTemplateResponse CreateTemplate(1: CreateTemplateRequest req)
    // POST /api/v1/template/set_default
    SetTemplateDefaultResponse SetTemplateDefault(1: SetTemplateDefaultRequest req)


    // 转录相关接口
    // 

    // 其他接口
    // GET /api/v1/user/get_profile
    GetUserProfileResponse GetUserProfile(1: GetUserProfileRequest req)
    // POST /api/v1/user/update_profile
    UpdateUserProfileResponse UpdateUserProfile(1: UpdateUserProfileRequest req)
    // POST /api/v1/user/update_ai_setting
    UpdateUserAiSettingResponse UpdateUserAiSetting(1: UpdateUserAiSettingRequest req)
}
