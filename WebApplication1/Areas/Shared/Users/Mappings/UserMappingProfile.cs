using AutoMapper;
using routent.AdminAPI.Models.Entities;
using routent.AdminAPI.DTOs.Users;
using routent.AdminAPI.DTOs.Auth;

namespace routent.AdminAPI.Mappings;

public class UserMappingProfile : Profile
{
    public UserMappingProfile()
    {
        CreateMap<AdminAccount, AdminProfileDto>();
    }
}
